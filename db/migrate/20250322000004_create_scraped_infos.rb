class CreateScrapedInfos < ActiveRecord::Migration[6.1]
  def change
    create_table :scraped_infos, id: :uuid do |t|
      t.string :source_type, null: false # tdh, website, etc.
      t.jsonb :data
      t.datetime :last_scraped_at
      t.uuid :tool_id, foreign_key: true
      t.timestamps
    end
    add_index :scraped_infos, [:source_type, :tool_id], unique: true
  end
end 