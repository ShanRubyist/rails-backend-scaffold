class Tag < ApplicationRecord
  has_many :tool_tags, dependent: :destroy
  has_many :tools, through: :tool_tags
  
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  
  before_validation :generate_slug, if: -> { slug.blank? }
  
  private
  
  def generate_slug
    self.slug = name.parameterize
  end
end 