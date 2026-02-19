# frozen_string_literal: true

class CreateRiskAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :risk_alerts do |t|
      t.string :alert_type, index: true
      t.float :risk_score, default: 0.0
      t.text :description
      t.boolean :is_read, default: false, index: true
      t.references :related_transaction, null: true, foreign_key: { to_table: :transactions }, index: true
      t.string :related_address, index: true

      t.timestamps
    end

    # Compound index for finding unread alerts sorted by risk
    add_index :risk_alerts, [:is_read, :risk_score]
    # Index for finding alerts by address
    add_index :risk_alerts, [:related_address, :created_at]
    # Index for finding recent alerts
    add_index :risk_alerts, :created_at
  end
end