class CreateErrorLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :error_logs, id: :uuid do |t|
      t.integer :origin_type, null: false, default: 0
      t.string :error_type, null: false
      t.text :message, null: false
      t.text :backtrace, null: false
      t.string :controller_name
      t.string :action_name
      t.string :user_email
      t.timestamps
    end
  end
end