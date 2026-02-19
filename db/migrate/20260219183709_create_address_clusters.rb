# frozen_string_literal: true

class CreateAddressClusters < ActiveRecord::Migration[8.1]
  def change
    create_table :address_clusters do |t|
      t.string :cluster_name
      t.integer :address_count
      t.string :cluster_type
      t.float :cluster_score

      t.timestamps
    end
  end
end
