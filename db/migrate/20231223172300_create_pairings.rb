class CreatePairings < ActiveRecord::Migration[7.0]
  def change
    create_table :pairings do |t|
      t.references :event, null: false
      t.references :santa, foreign_key: { to_table: :users }, null: false
      t.references :person, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end
