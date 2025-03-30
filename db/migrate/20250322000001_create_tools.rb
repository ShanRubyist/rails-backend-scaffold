class CreateTools < ActiveRecord::Migration[6.1]
  def change
    create_table :tools, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.string :url
      t.string :logo_url
      t.boolean :published, default: false
      t.integer :popularity, default: 0
      t.string :pricing_type # free, freemium, paid
      t.timestamps
    end
    add_index :tools, :name, unique: true
    add_index :tools, :published
  end
end 