# frozen_string_literal: true

class AddressPattern < ApplicationRecord
  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  validates :address, presence: true, format: { with: /\A0x[a-fA-F0-9]{40}\z/, message: "must be a valid Ethereum address" }
  validates :pattern_type, presence: true, inclusion: {
    in: %w[dormant_activation rapid_transfers circular_pattern token_pump flash_loan unusual_cluster],
    message: "%{value} is not a valid pattern type"
  }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :detected_at, presence: true

  # ============================================================================
  # SCOPES
  # ============================================================================

  # Find patterns with high confidence (70+)
  scope :high_confidence, -> { where("confidence >= ?", 70) }

  # Find patterns with medium confidence (40-69)
  scope :medium_confidence, -> { where("confidence >= ? AND confidence < ?", 40, 70) }

  # Find patterns with low confidence (< 40)
  scope :low_confidence, -> { where("confidence < ?", 40) }

  # Find patterns by type
  scope :by_type, ->(type) { where(pattern_type: type) }

  # Find patterns for a specific address
  scope :for_address, ->(address) { where(address: address) }

  # Find recent patterns (last N hours)
  scope :recent, ->(hours = 24) { where("detected_at > ?", hours.hours.ago) }

  # Find patterns sorted by confidence (highest first)
  scope :by_confidence, -> { order(confidence: :desc) }

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================

  # Check if this pattern is high-confidence
  def high_confidence?
    confidence >= 70
  end

  # Check if this pattern is suspicious
  def suspicious?
    confidence >= 60
  end

  # Get the pattern data as a readable summary
  def pattern_summary
    case pattern_type
    when "dormant_activation"
      "Address inactive for #{pattern_data['dormant_days']} days, then moved #{pattern_data['value_moved']} ETH"
    when "rapid_transfers"
      "#{pattern_data['transfer_count']} transfers in #{pattern_data['time_window_minutes']} minutes"
    when "circular_pattern"
      "Found #{pattern_data['cycle_count']} circular transfer cycles"
    when "token_pump"
      "Rapid token buys (#{pattern_data['buy_count']}) followed by dumps (#{pattern_data['sell_count']})"
    when "flash_loan"
      "Flash loan detected with profit of #{pattern_data['profit']} ETH"
    when "unusual_cluster"
      "Address appears in cluster with #{pattern_data['similar_addresses']} other suspicious addresses"
    else
      "Unknown pattern detected"
    end
  end

  # Get a summary of the pattern
  def summary
    {
      id: id,
      address: address,
      type: pattern_type,
      confidence: confidence,
      description: pattern_summary,
      detected_at: detected_at,
      suspicious: suspicious?,
      data: pattern_data
    }
  end

  # ============================================================================
  # CLASS METHODS
  # ============================================================================

  # Create a dormant activation pattern
  def self.create_dormant_activation(address, dormant_days, value_moved)
    create(
      address: address,
      pattern_type: "dormant_activation",
      confidence: [dormant_days / 30.0 * 100, 100].min, # Higher dormancy = higher confidence
      pattern_data: {
        dormant_days: dormant_days,
        value_moved: value_moved
      },
      detected_at: Time.current
    )
  end

  # Create a rapid transfers pattern
  def self.create_rapid_transfers(address, transfer_count, time_window_minutes)
    confidence = (transfer_count / 10.0) * 100 # More transfers = higher confidence
    create(
      address: address,
      pattern_type: "rapid_transfers",
      confidence: [confidence, 100].min,
      pattern_data: {
        transfer_count: transfer_count,
        time_window_minutes: time_window_minutes
      },
      detected_at: Time.current
    )
  end

  # Create a circular pattern
  def self.create_circular_pattern(address, cycle_count)
    create(
      address: address,
      pattern_type: "circular_pattern",
      confidence: cycle_count * 20, # Each cycle adds confidence
      pattern_data: {
        cycle_count: cycle_count
      },
      detected_at: Time.current
    )
  end
end
