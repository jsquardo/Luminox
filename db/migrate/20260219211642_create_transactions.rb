# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :tx_hash
      t.string :from_address, index: true
      t.string :to_address, index: true
      t.decimal :value, precision: 30, scale: 8, default: 0
      t.decimal :gas_price, precision: 30, scale: 8, default: 0
      t.integer :block_number, index: true
      t.datetime :timestamp, index: true
      t.string :token_symbol
      t.boolean :is_contract_interaction, default: false
      t.float :anomaly_score, default: 0.0
      t.boolean :is_alerted, default: false

      t.timestamps
    end

    add_index :transactions, :tx_hash, unique: true
    add_index :transactions, [:from_address, :timestamp]
    add_index :transactions, [:to_address, :timestamp]
    add_index :transactions, :anomaly_score
  end
end
