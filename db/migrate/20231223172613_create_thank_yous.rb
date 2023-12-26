class CreateThankYous < ActiveRecord::Migration[7.0]
  def change
    create_table :thank_yous do |t|
      t.string :message, null: false
      t.references :event, null: false
      t.references :sender, foreign_key: { to_table: :users }, null: false
      t.references :recipient, foreing_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end
