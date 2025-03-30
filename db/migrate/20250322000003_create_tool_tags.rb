class CreateToolTags < ActiveRecord::Migration[6.1]
  def change
    create_table :tool_tags, id: :uuid do |t|
      t.uuid :tool_id, null: false, foreign_key: true
      t.uuid :tag_id, null: false, foreign_key: true
      t.timestamps
    end
    add_index :tool_tags, [:tool_id, :tag_id], unique: true
  end
end 