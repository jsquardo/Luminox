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

ActiveRecord::Schema[8.1].define(version: 2026_02_19_183710) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "address_clusters", force: :cascade do |t|
    t.integer "address_count"
    t.string "cluster_name"
    t.float "cluster_score"
    t.string "cluster_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "addresses", force: :cascade do |t|
    t.string "address"
    t.bigint "address_cluster_id"
    t.datetime "created_at", null: false
    t.datetime "first_seen"
    t.boolean "is_contract", default: false
    t.string "label"
    t.datetime "last_seen"
    t.float "risk_score", default: 0.0
    t.decimal "total_received", precision: 30, scale: 8, default: "0.0"
    t.decimal "total_sent", precision: 30, scale: 8, default: "0.0"
    t.integer "transaction_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_addresses_on_address", unique: true
    t.index ["address_cluster_id"], name: "index_addresses_on_address_cluster_id"
    t.index ["last_seen"], name: "index_addresses_on_last_seen"
    t.index ["risk_score"], name: "index_addresses_on_risk_score"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "addresses", "address_clusters"
  add_foreign_key "sessions", "users"
end
