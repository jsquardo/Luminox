# frozen_string_literal: true

class Transaction < ApplicationRecord
  # ============================================================================
  # RELATIONSHIPS
  # ============================================================================

  # A transaction belongs to two addresses (sender and receiver)
  # We don't use standard foreign keys because addresses are identified by
  # their address string, not an ID
  belongs_to :from_address_model, foreign_key: "from_address", primary_key: "address", class_name: "Address", optional: true
  belongs_to :to_address_model, foreign_key: "to_address", primary_key: "address", class_name: "Address", optional: true

  # A transaction can have many risk alerts
  has_many :risk_alerts, dependent: :destroy

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :tx_hash, presence: true, uniqueness: true
  # Ethereum transaction hashes are "0x" followed by 64 hex characters
  validates :tx_hash, format: { with: /\A0x[a-fA-F0-9]{64}\z/, message: "must be a valid Ethereum transaction hash" }

  validates :from_address, :to_address, presence: true
  validates :from_address, :to_address, format: { with: /\A0x[a-fA-F0-9]{40}\z/, message: "must be a valid Ethereum address" }

  validates :value, :gas_price, numericality: { greater_than_or_equal_to: 0 }
  validates :block_number, numericality: { greater_than_or_equal_to: 0 }
  validates :timestamp, presence: true

  # ============================================================================
  # SCOPES
  # ============================================================================

  # Find transactions with high anomaly scores
  scope :high_anomaly, -> { where("anomaly_score >= ?", 70) }

  # Find transactions that haven't been alerted yet
  scope :not_alerted, -> { where(is_alerted: false) }

  # Find transactions from a specific address
  scope :from, ->(address) { where(from_address: address) }

  # Find transactions to a specific address
  scope :to, ->(address) { where(to_address: address) }

  # Find transactions above a certain value (in wei)
  scope :high_value, ->(min_value) { where("value >= ?", min_value) }

  # Find transactions within a time range
  scope :in_time_range, ->(start_time, end_time) { where(timestamp: start_time..end_time) }

  # Find recent transactions (last N hours)
  scope :recent, ->(hours = 24) { where("timestamp > ?", hours.hours.ago) }

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================

  # Check if this is a high-value transaction
  def high_value?
    # A whale transaction is anything above 100 ETH (in wei)
    # 1 ETH = 1e18 wei, so 100 ETH = 1e20 wei
    value >= 100_000_000_000_000_000_000
  end

  # Check if this transaction is suspicious (high anomaly score)
  def suspicious?
    anomaly_score >= 70
  end

  # Check if this is a circular transaction (sending to same address you receive from)
  def circular_transfer?
    from_address == to_address
  end

  # Get the value in ETH (human readable format)
  # 1 ETH = 1e18 wei
  def value_in_eth
    (value / 1_000_000_000_000_000_000.0).round(8)
  end

  # Mark this transaction as alerted if it's suspicious
  def alert_if_suspicious!
    return if is_alerted?
    return unless suspicious?

    self.is_alerted = true
    save
    create_alert
  end

  # Create a risk alert for this transaction
  def create_alert
    RiskAlert.create(
      alert_type: "suspicious_transaction",
      related_transaction_id: id,
      related_address: from_address,
      risk_score: anomaly_score,
      description: "Transaction #{tx_hash} has anomaly score of #{anomaly_score}"
    )
  end

  # ============================================================================
  # CLASS METHODS
  # ============================================================================

  # Find all transactions between two addresses
  def self.between(address_a, address_b)
    where("(from_address = ? AND to_address = ?) OR (from_address = ? AND to_address = ?)",
          address_a, address_b, address_b, address_a)
  end

  # Get the total value transferred between two addresses
  def self.total_value_between(address_a, address_b)
    between(address_a, address_b).sum(:value)
  end
end
