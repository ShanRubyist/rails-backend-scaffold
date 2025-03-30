class CreateTags < ActiveRecord::Migration[6.1]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.timestamps
    end
    add_index :tags, :name, unique: true
    add_index :tags, :slug, unique: true
  end
end 