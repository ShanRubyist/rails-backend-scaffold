class CreateAiCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_calls, id: :uuid do |t|
      t.uuid :conversation_id, null: false
      t.string :task_id, null: false
      t.string :prompt, null: false
      t.string :status, null: false
      t.json :input, null: false
      t.json :data
      t.integer "cost_credits", null: false
      t.string "system_prompt"
      t.string "business_type"

      t.timestamps
    end

    add_index :ai_calls, :task_id, unique: true
  end
end