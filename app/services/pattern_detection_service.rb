# frozen_string_literal: true

class PatternDetectionService
  # ============================================================================
  # Detects suspicious patterns across multiple transactions.
  # Unlike RiskScoringService which scores individual transactions,
  # this service looks for behavioral patterns over time:
  #
  #   - Dormant activation (wallet inactive 30+ days, suddenly active)
  #   - Rapid transfers (many transactions in a short window)
  #   - Fan-out pattern (one address sending to many new addresses quickly)
  #   - Fan-in pattern (many addresses sending to one address quickly)
  #   - Layering (funds moving through a chain of addresses)
  # ============================================================================

  DORMANCY_THRESHOLD_DAYS = 30
  RAPID_TRANSFER_WINDOW = 10.minutes
  RAPID_TRANSFER_COUNT = 5
  FAN_OUT_WINDOW = 1.hour
  FAN_OUT_COUNT = 10
  FAN_IN_WINDOW = 1.hour
  FAN_IN_COUNT = 10
  LAYERING_DEPTH = 3

  # ============================================================================
  # PUBLIC METHODS
  # ============================================================================

  # Analyze a single address for all patterns
  def analyze_address(address)
    detected = []

    detected << detect_dormant_activation(address)
    detected << detect_rapid_transfers(address)
    detected << detect_fan_out(address)
    detected << detect_fan_in(address)

    detected.compact
  end

  # Analyze all addresses that have been active recently
  def analyze_recent_activity(hours: 24)
    recent_addresses = Transaction
      .where("timestamp > ?", hours.hours.ago)
      .pluck(:from_address, :to_address)
      .flatten
      .uniq
      .compact

    Rails.logger.info "PatternDetectionService analyzing #{recent_addresses.count} addresses"

    results = {}
    recent_addresses.each do |address|
      patterns = analyze_address(address)
      results[address] = patterns if patterns.any?
    end

    Rails.logger.info "PatternDetectionService found patterns in #{results.count} addresses"
    results
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  # Wallet was inactive for 30+ days, then suddenly sent a transaction
  def detect_dormant_activation(address)
    transactions = Transaction
      .where(from_address: address)
      .order(timestamp: :asc)

    return nil if transactions.count < 2

    transactions.each_cons(2) do |prev_tx, curr_tx|
      gap_days = (curr_tx.timestamp - prev_tx.timestamp) / 1.day

      next unless gap_days >= DORMANCY_THRESHOLD_DAYS

      return store_pattern(
        address: address,
        pattern_type: "dormant_activation",
        confidence: [gap_days / DORMANCY_THRESHOLD_DAYS * 50, 100].min,
        data: {
          dormant_days: gap_days.round(1),
          last_tx: prev_tx.tx_hash,
          activation_tx: curr_tx.tx_hash,
          activation_value: curr_tx.value
        }
      )
    end

    nil
  end

  # Many outgoing transactions in a short time window — bot or mixer behavior
  def detect_rapid_transfers(address)
    recent = Transaction
      .where(from_address: address)
      .where("timestamp > ?", RAPID_TRANSFER_WINDOW.ago)
      .order(timestamp: :asc)

    return nil if recent.count < RAPID_TRANSFER_COUNT

    store_pattern(
      address: address,
      pattern_type: "rapid_transfers",
      confidence: [recent.count.to_f / RAPID_TRANSFER_COUNT * 50, 100].min,
      data: {
        transfer_count: recent.count,
        window_minutes: RAPID_TRANSFER_WINDOW / 60,
        first_tx: recent.first.tx_hash,
        last_tx: recent.last.tx_hash,
        total_value: recent.sum(:value)
      }
    )
  end

  # One address sending to many unique addresses quickly — layering/distribution
  def detect_fan_out(address)
    recent = Transaction
      .where(from_address: address)
      .where("timestamp > ?", FAN_OUT_WINDOW.ago)

    unique_recipients = recent.pluck(:to_address).uniq.count
    return nil if unique_recipients < FAN_OUT_COUNT

    store_pattern(
      address: address,
      pattern_type: "fan_out",
      confidence: [unique_recipients.to_f / FAN_OUT_COUNT * 60, 100].min,
      data: {
        unique_recipients: unique_recipients,
        window_hours: FAN_OUT_WINDOW / 3600,
        total_value: recent.sum(:value)
      }
    )
  end

  # Many unique addresses sending to one address quickly — aggregation/collection
  def detect_fan_in(address)
    recent = Transaction
      .where(to_address: address)
      .where("timestamp > ?", FAN_IN_WINDOW.ago)

    unique_senders = recent.pluck(:from_address).uniq.count
    return nil if unique_senders < FAN_IN_COUNT

    store_pattern(
      address: address,
      pattern_type: "fan_in",
      confidence: [unique_senders.to_f / FAN_IN_COUNT * 60, 100].min,
      data: {
        unique_senders: unique_senders,
        window_hours: FAN_IN_WINDOW / 3600,
        total_value: recent.sum(:value)
      }
    )
  end

  # Store a detected pattern in the database
  def store_pattern(address:, pattern_type:, confidence:, data:)
    pattern = AddressPattern.find_or_initialize_by(
      address: address,
      pattern_type: pattern_type
    )

    pattern.update!(
      confidence: confidence.round(2),
      pattern_data: data,
      detected_at: Time.current
    )

    Rails.logger.info(
      "Pattern detected — address: #{address[0..10]}..., " \
      "type: #{pattern_type}, confidence: #{confidence.round(2)}"
    )

    pattern
  end
end
