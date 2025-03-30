class ScrapedInfo < ApplicationRecord
  belongs_to :tool, optional: true
  
  validates :source_type, presence: true
  # validates :source_id, presence: true, uniqueness: { scope: :source_type }

  scope :tdh_info, -> { where(source_type: 'tdh') }
  # scope :website_info, -> { where(source_type: 'website') }
end