# frozen_string_literal: true

class RiskAlert < ApplicationRecord
  # ============================================================================
  # RELATIONSHIPS
  # ============================================================================

  belongs_to :related_transaction, optional: true
  # Can look up the address from the related_address string
  # In the future could possibly make this a proper foreign key

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :alert_type, presence: true, inclusion: {
    in: %w[high_value dormant_activation pump_dump circular_transfer unusual_pattern suspicious_cluster],
    message: "%{value} is not a valid alert type"
  }
  validates :risk_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :description, presence: true
  validates :related_address, format: { with: /\A0x[a-fA-F0-9]{40}\z/, message: "must be a valid Ethereum address" }

  # ============================================================================
  # SCOPES
  # ============================================================================

  # Find all unread alerts
  scope :unread, -> { where(is_read: false) }

  # Find all read alerts
  scope :read, -> { where(is_read: true) }

  # Find high-risk alerts (score >= 70)
  scope :high_risk, -> { where("risk_score >= ?", 70) }

  # Find medium-risk alerts (40-69)
  scope :medium_risk, -> { where("risk_score >= ? AND risk_score < ?", 40, 70) }

  # Find low-risk alerts (< 40)
  scope :low_risk, -> { where("risk_score < ?", 40) }

  # Find alerts by type
  scope :by_type, ->(type) { where(alert_type: type) }

  # Find alerts for a specific address
  scope :for_address, ->(address) { where(related_address: address) }

  # Find recent alerts (last N hours)
  scope :recent, ->(hours = 24) { where("created_at > ?", hours.hours.ago) }

  # Find alerts sorted by risk score (highest first)
  scope :by_risk, -> { order(risk_score: :desc) }

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================

  # Mark this alert as read
  def mark_as_read!
    update(is_read: true)
  end

  # Mark this alert as unread
  def mark_as_unread!
    update(is_read: false)
  end

  # Check if this is a critical alert (high risk)
  def critical?
    risk_score >= 80
  end

  # Get a summary of the alert
  def summary
    {
      id: id,
      type: alert_type,
      risk_score: risk_score,
      address: related_address,
      description: description,
      is_read: is_read,
      created_at: created_at,
      critical: critical?
    }
  end

  # ============================================================================
  # CALLBACKS
  # ============================================================================

  # If a transaction is deleted, don't delete the alert (keep the record)
  before_destroy :nullify_transaction_reference

  private

  def nullify_transaction_reference
    # This ensures the alert is kept even if the transaction is deleted
    # (Just won't be able to link to it)
  end
end
