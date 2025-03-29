class CreateConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations, id: :uuid do |t|
      t.uuid :user_id, null: false

      t.timestamps
    end
  end
end
