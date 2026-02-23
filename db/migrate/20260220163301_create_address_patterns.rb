# frozen_string_literal: true

class CreateAddressPatterns < ActiveRecord::Migration[8.1]
  def change
    create_table :address_patterns do |t|
      t.string :address, index: true
      t.string :pattern_type, index: true
      t.jsonb :pattern_data, default: {}
      t.float :confidence, default: 0.0
      t.datetime :detected_at, index: true

      t.timestamps
    end

    # Compound index for finding patterns for a specific address
    add_index :address_patterns, [:address, :pattern_type]
    # Index for finding recent patterns
    add_index :address_patterns, [:detected_at, :confidence]
  end
end