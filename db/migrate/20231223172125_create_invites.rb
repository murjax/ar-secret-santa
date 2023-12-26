class CreateInvites < ActiveRecord::Migration[7.0]
  def change
    create_table :invites do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.integer :status, null: false, default: 0
      t.references :event, null: false
      t.references :user

      t.timestamps
    end
  end
end
