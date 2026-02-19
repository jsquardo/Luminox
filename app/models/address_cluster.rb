# frozen_string_literal: true

class AddressCluster < ApplicationRecord
  # ============================================================================
  # RELATIONSHIPS
  # ============================================================================

  # A cluster has many addresses
  # When we delete a cluster, all associated addresses get deleted too
  has_many :addresses, dependent: :destroy

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :cluster_name, presence: true
  validates :cluster_type, presence: true, inclusion: { in: %w[exchange bot_network whale_group suspicious_ring mixer unknown], message: "%{value} is not a valid cluster type" }

  # ============================================================================
  # SCOPES
  # ============================================================================

  # Find all high-risk clusters
  scope :high_risk, -> { where("cluster_score >= ?", 70) }

  # Find all medium-risk clusters
  scope :medium_risk, -> { where("cluster_score >= ? AND cluster_score < ?", 40, 70) }

  # Find all low-risk clusters
  scope :low_risk, -> { where("cluster_score < ?", 40) }

  # Find clusters with a certain type
  scope :by_type, ->(type) { where(cluster_type: type) }

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================

  # Recalculate the cluster score based on all addresses in it
  # The cluster score is the average of all address risk scores
  def recalculate_cluster_score
    if addresses.empty?
      self.cluster_score = 0.0
    else
      self.cluster_score = addresses.average(:risk_score).to_f
    end
    save
  end

  # Update the address count to match actual number of addresses
  def update_address_count
    self.address_count = addresses.count
    save
  end

  # Get the average transaction count across all addresses in the cluster
  def average_transaction_count
    return 0 if addresses.empty?

    addresses.average(:transaction_count).to_i
  end

  # Get the total value sent by all addresses in this cluster
  def total_value_sent
    addresses.sum(:total_sent)
  end

  # Get the total value received by all addresses in this cluster
  def total_value_received
    addresses.sum(:total_received)
  end

  # Check if this cluster is recently active
  def recently_active?
    addresses.recently_active.any?
  end

  # Get a summary of the cluster
  def summary
    {
      name: cluster_name,
      type: cluster_type,
      risk_score: cluster_score,
      address_count: address_count,
      total_sent: total_value_sent,
      total_received: total_value_received,
      is_active: recently_active?
    }
  end
end
