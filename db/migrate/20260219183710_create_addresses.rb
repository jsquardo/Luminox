# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :address
      t.string :label
      t.datetime :first_seen
      t.datetime :last_seen
      t.integer :transaction_count, default: 0
      t.decimal :total_sent, precision: 30, scale: 8, default: 0
      t.decimal :total_received, precision: 30, scale: 8, default: 0
      t.boolean :is_contract, default: false
      t.float :risk_score, default: 0.0
      t.references :address_cluster, null: true, foreign_key: true

      t.timestamps
    end
    add_index :addresses, :address, unique: true
    add_index :addresses, :risk_score
    add_index :addresses, :last_seen
  end
end
