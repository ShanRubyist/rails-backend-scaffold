class Tool < ApplicationRecord
  has_many :tool_tags, dependent: :destroy
  has_many :tags, through: :tool_tags
  has_many :scraped_infos, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  def self.search_by_query(query)
    where("tools.name ILIKE ? OR tools.description ILIKE ?", "%#{query}%", "%#{query}%")
  end

  def self.search_by_tags(tags)
    return self if tags.empty?
    joins(:tags).where(tags: { id: tags }).distinct
  end

  def self.order_by(s)
    case s
    when 'time_desc'
      order("created_at desc")
    when 'time_asc'
      order("created_at asc")
    else
      order("created_at desc")
    end
  end

  def alternatives
    Tool.published.joins(:tags)
        .where(tags: { id: tags.select(:id) }) # 匹配目标 tool 的 tags
        .where.not(id: id) # 排除自己
        .group(:id) # 按 tool 分组
        .select('tools.*, COUNT(tags.id) AS common_tags_count') # 计算共同 tag 数量
        .order(common_tags_count: :desc, created_at: :asc) # 排序规则
        .limit(5)
  end

  def self.monthly_tools(date)
    Tool.where(created_at: date.beginning_of_month..date.end_of_month)
  end
end 