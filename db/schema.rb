# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_02_17_163842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "date", null: false
    t.boolean "send_reminder", default: false, null: false
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fee", precision: 8, scale: 2, default: "0.0", null: false
    t.index ["owner_id"], name: "index_events_on_owner_id"
  end

  create_table "invites", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "status", default: 0, null: false
    t.bigint "event_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_invites_on_event_id"
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "pairings", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "santa_id", null: false
    t.bigint "person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_pairings_on_event_id"
    t.index ["person_id"], name: "index_pairings_on_person_id"
    t.index ["santa_id"], name: "index_pairings_on_santa_id"
  end

  create_table "thank_yous", force: :cascade do |t|
    t.string "message", null: false
    t.bigint "event_id", null: false
    t.bigint "sender_id", null: false
    t.bigint "recipient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_thank_yous_on_event_id"
    t.index ["recipient_id"], name: "index_thank_yous_on_recipient_id"
    t.index ["sender_id"], name: "index_thank_yous_on_sender_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "hashed_password"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wish_list_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "url"
    t.string "site_image_url"
    t.string "site_description"
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_wish_list_items_on_event_id"
    t.index ["user_id"], name: "index_wish_list_items_on_user_id"
  end

  add_foreign_key "events", "users", column: "owner_id"
  add_foreign_key "pairings", "users", column: "person_id"
  add_foreign_key "pairings", "users", column: "santa_id"
  add_foreign_key "thank_yous", "users", column: "sender_id"
end
