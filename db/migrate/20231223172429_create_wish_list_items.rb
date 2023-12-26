class CreateWishListItems < ActiveRecord::Migration[7.0]
  def change
    create_table :wish_list_items do |t|
      t.string :name, null: false
      t.string :url
      t.string :site_image_url
      t.string :site_description
      t.references :event, null: false
      t.references :user, null: false

      t.timestamps
    end
  end
end
