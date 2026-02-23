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

ActiveRecord::Schema[8.1].define(version: 2026_02_23_000000) do
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

  create_table "address_patterns", force: :cascade do |t|
    t.string "address"
    t.float "confidence", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "detected_at"
    t.jsonb "pattern_data", default: {}
    t.string "pattern_type"
    t.datetime "updated_at", null: false
    t.index ["address", "pattern_type"], name: "index_address_patterns_on_address_and_pattern_type"
    t.index ["address"], name: "index_address_patterns_on_address"
    t.index ["detected_at", "confidence"], name: "index_address_patterns_on_detected_at_and_confidence"
    t.index ["detected_at"], name: "index_address_patterns_on_detected_at"
    t.index ["pattern_type"], name: "index_address_patterns_on_pattern_type"
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
