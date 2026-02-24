# frozen_string_literal: true

class TokenTransfer < ApplicationRecord
  # ============================================================================
  # RELATIONSHIPS
  # ============================================================================

  belongs_to :from_address_model, foreign_key: "from_address", primary_key: "address", class_name: "Address", optional: true
  belongs_to :to_address_model, foreign_key: "to_address", primary_key: "address", class_name: "Address", optional: true

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :tx_hash, presence: true
  validates :from_address, :to_address, presence: true
  validates :from_address, :to_address, format: {with: /\A0x[a-fA-F0-9]{40}\z/, message: "must be a valid Ethereum address"}
  validates :token_address, presence: true, format: {with: /\A0x[a-fA-F0-9]{40}\z/, message: "must be a valid Ethereum address"}
  validates :timestamp, presence: true
  validates :amount, numericality: {greater_than_or_equal_to: 0}, allow_nil: true

  # ============================================================================
  # SCOPES
  # ============================================================================

  scope :suspicious, -> { where(is_suspicious: true) }
  scope :for_token, ->(token_address) { where(token_address: token_address) }
  scope :from_addr, ->(address) { where(from_address: address) }
  scope :to_addr, ->(address) { where(to_address: address) }
  scope :recent, ->(hours = 24) { where("timestamp > ?", hours.hours.ago) }
  scope :in_time_range, ->(start_time, end_time) { where(timestamp: start_time..end_time) }
  scope :for_address, ->(address) { where("from_address = ? OR to_address = ?", address, address) }

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================

  def involves_address?(address)
    from_address == address || to_address == address
  end

  def mark_suspicious!(anomaly_type)
    update!(is_suspicious: true, anomaly_type: anomaly_type)
  end
end
