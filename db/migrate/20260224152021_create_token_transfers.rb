# frozen_string_literal: true

class CreateTokenTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :token_transfers do |t|
      t.string :tx_hash, null: false
      t.string :from_address, null: false
      t.string :to_address, null: false
      t.string :token_address, null: false
      t.string :token_symbol
      t.decimal :amount, precision: 78, scale: 0
      t.datetime :timestamp, null: false
      t.boolean :is_suspicious, default: false, null: false
      t.string :anomaly_type

      t.timestamps
    end

    add_index :token_transfers, :tx_hash
    add_index :token_transfers, :from_address
    add_index :token_transfers, :to_address
    add_index :token_transfers, :token_address
    add_index :token_transfers, :timestamp
    add_index :token_transfers, :is_suspicious
  end
end
