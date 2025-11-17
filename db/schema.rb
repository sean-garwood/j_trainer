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

ActiveRecord::Schema[8.0].define(version: 2025_10_23_165604) do
  create_table "clues", force: :cascade do |t|
    t.integer "round"
    t.integer "clue_value"
    t.integer "daily_double_value"
    t.text "category"
    t.text "comments"
    t.text "clue_text"
    t.text "correct_response"
    t.string "air_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drill_clues", force: :cascade do |t|
    t.integer "drill_id", null: false
    t.integer "clue_id", null: false
    t.integer "result"
    t.float "response_time"
    t.string "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clue_id"], name: "index_drill_clues_on_clue_id"
    t.index ["drill_id"], name: "index_drill_clues_on_drill_id"
  end

  create_table "drills", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "correct_count", default: 0
    t.integer "incorrect_count", default: 0
    t.integer "pass_count", default: 0
    t.integer "clues_seen_count", default: 0
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_drills_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "drill_clues", "clues"
  add_foreign_key "drill_clues", "drills"
  add_foreign_key "drills", "users"
  add_foreign_key "sessions", "users"
end
