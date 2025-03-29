class Conversation < ApplicationRecord
  belongs_to :user

  has_many :ai_calls
end
