class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.datetime :date, null: false
      t.boolean :send_reminder, null: false, default: false
      t.references :owner, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end
