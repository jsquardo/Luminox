# frozen_string_literal: true

class Address < ApplicationRecord
  # ============================================================================
  # RELATIONSHIPS
  # ============================================================================

  # Outgoing transactions: transactions where THIS address is the "from" address
  # Using foreign_key and primary_key because we're not using the typical Rails ID
  # Using the Ethereum addrress as the key
  has_many :outgoing_transactions, foreign_key: "from_address", primary_key: "address", dependent: :destroy, class_name: "Transaction"

  # Incoming transactions: transactions where THIS address is the "to" address
  has_many :incoming_transactions, foreign_key: "to_address", primary_key: "address", dependent: :destroy, class_name: "Transaction"

  # Risk alerts related to this address
  has_many :risk_alerts, foreign_key: "related_address", primary_key: "address", dependent: :destroy

  # This address belongs to a cluster (group of addresses we think same entity controls)
  belongs_to :address_cluster, optional: true

  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  # These ensure data integrity - we won't save bad data to the database

  validates :address, presence: true, uniqueness: true
  # Ethereum addresses are always "0x" followed by exactly 40 hexadecimal characters
  validates :address, format: { with: /\A0x[a-fA-F0-9]{40}\z/, message: "must be a valid Ethereum address" }

  # ============================================================================
  # CALLBACKS
  # ============================================================================
  # These run automatically at certain times in the record's lifecycle
  before_create :set_first_seen

  # ============================================================================
  # SCOPES
  # ============================================================================
  # These are reusable queries that help us filter addresses easily

  # Find all addresses with high risk scores (70+)
  scope :high_risk, -> { where("risk_score >= ?", 70)}

  # Find all addresses with medium risk scores (40-69)
  scope :medium_risk, -> { where("risk_score >= ? AND risk_score < ?", 40, 70) }

  # Find all addresses with low risk scores (below 40)
  scope :low_risk, -> { where("risk_score < ?", 40) }

  # Find addresses that have been involved in at least one transaction
  scope :with_transactions, -> { where("transaction_count > ?", 0) }

  # Find addresses that were active in the last 24 hours
  scope :recently_active, -> { where("last_seen > ?", 24.hours.ago) }

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  # These are actions we can perform on a single address

  # Update all the calculated metrics for this address
  # This is called after we process new transactions

  def update_metrics
    self.transaction_count = outgoing_transactions.count + incoming_transactions.count
    self.total_sent - outgoing_transactions.sum(:value) || 0
    self.total_recieved = incoming_transactions.sum(:value) || 0

    # Get the most recent transaction timestamp from either outgoing or incoming
    last_sent = outgoing_transactions.maximum(:timestamp)
    last_received = incoming_transactions.maximum(:timestamp)
    self.last_seen = [last_sent, last_received].compact.max

    save
  end

  # Recalculate the risk score for this address
  # This will call our risk scoring service
  def recalculate_risk_score
    self.risk_score = RiskScoringService.calculate_address_risk(self)
    save
  end

  # Check if this address is dormant (hasn't been active recently)
  def dormant?
    return true if last_seen.nil?

    last_seen < 30.days.ago
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  # Set the first_seen timestamp when we create a new address
  def set_first_seen
    self.first_seen ||= Time.current
  end
end
