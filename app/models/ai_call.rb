class AiCall < ApplicationRecord
  belongs_to :conversation

  has_many_attached :input_media
  has_many_attached :generated_media

  scope :succeeded_ai_calls, -> { where("ai_calls.status = ?", 'success') }

  def update_ai_call_status(h)
    self.update(status: h[:status], data: h)
  end
end
