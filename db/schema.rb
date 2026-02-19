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

ActiveRecord::Schema[8.1].define(version: 2026_02_19_225643) do
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

  create_table "risk_alerts", force: :cascade do |t|
    t.string "alert_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_read", default: false
    t.string "related_address"
    t.bigint "related_transaction_id"
    t.float "risk_score", default: 0.0
    t.datetime "updated_at", null: false
    t.index ["alert_type"], name: "index_risk_alerts_on_alert_type"
    t.index ["created_at"], name: "index_risk_alerts_on_created_at"
    t.index ["is_read", "risk_score"], name: "index_risk_alerts_on_is_read_and_risk_score"
    t.index ["is_read"], name: "index_risk_alerts_on_is_read"
    t.index ["related_address", "created_at"], name: "index_risk_alerts_on_related_address_and_created_at"
    t.index ["related_address"], name: "index_risk_alerts_on_related_address"
    t.index ["related_transaction_id"], name: "index_risk_alerts_on_related_transaction_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.float "anomaly_score", default: 0.0
    t.integer "block_number"
    t.datetime "created_at", null: false
    t.string "from_address"
    t.decimal "gas_price", precision: 30, scale: 8, default: "0.0"
    t.boolean "is_alerted", default: false
    t.boolean "is_contract_interaction", default: false
    t.datetime "timestamp"
    t.string "to_address"
    t.string "token_symbol"
    t.string "tx_hash"
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 30, scale: 8, default: "0.0"
    t.index ["anomaly_score"], name: "index_transactions_on_anomaly_score"
    t.index ["block_number"], name: "index_transactions_on_block_number"
    t.index ["from_address", "timestamp"], name: "index_transactions_on_from_address_and_timestamp"
    t.index ["from_address"], name: "index_transactions_on_from_address"
    t.index ["timestamp"], name: "index_transactions_on_timestamp"
    t.index ["to_address", "timestamp"], name: "index_transactions_on_to_address_and_timestamp"
    t.index ["to_address"], name: "index_transactions_on_to_address"
    t.index ["tx_hash"], name: "index_transactions_on_tx_hash", unique: true
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
  add_foreign_key "risk_alerts", "transactions", column: "related_transaction_id"
  add_foreign_key "sessions", "users"
end
