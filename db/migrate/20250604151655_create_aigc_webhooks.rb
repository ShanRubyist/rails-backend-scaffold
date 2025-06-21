class CreateAigcWebhooks < ActiveRecord::Migration[7.0]
  def change
    create_table :aigc_webhooks, id: :uuid do |t|
      t.json :header
      t.json :data

      t.timestamps
    end
  end
end
