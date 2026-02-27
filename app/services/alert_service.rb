# frozen_string_literal: true

class AlertService
  # ============================================================================
  # Generates and manages risk alerts based on transaction scores
  # and detected patterns.
  #
  # Alert types:
  #   - high_value: Transaction above whale threshold
  #   - suspicious_transaction: High anomaly score on a transaction
  #   - dormant_activation: Wallet inactive 30+ days suddenly active
  #   - rapid_transfers: Many transfers in short window
  #   - fan_out: One address distributing to many quickly
  #   - fan_in: Many addresses collecting to one quickly
  # ============================================================================

  ALERT_SCORE_THRESHOLD = 20.0
  HIGH_VALUE_THRESHOLD_WEI = (100 * 1e18).to_i

  # ============================================================================
  # PUBLIC METHODS
  # ============================================================================

  # Generate alerts for all unalerted high-scoring transactions
  def alert_on_transactions
    flagged = Transaction.where("anomaly_score >= ?", ALERT_SCORE_THRESHOLD)
                         .where(is_alerted: false)

    count = 0
    flagged.each do |tx|
      create_transaction_alert(tx)
      tx.update!(is_alerted: true)
      count += 1
    end

    Rails.logger.info "AlertService created #{count} transaction alerts"
    count
  end

  # Generate alerts for all detected patterns
  def alert_on_patterns
    patterns = AddressPattern.where("detected_at > ?", 24.hours.ago)

    count = 0
    patterns.each do |pattern|
      next if alert_exists_for_pattern?(pattern)
      create_pattern_alert(pattern)
      count += 1
    end

    Rails.logger.info "AlertService created #{count} pattern alerts"
    count
  end

  # Run all alert checks
  def run
    tx_count = alert_on_transactions
    pattern_count = alert_on_patterns
    total = tx_count + pattern_count
    Rails.logger.info "AlertService run complete — #{total} total alerts created"
    {transaction_alerts: tx_count, pattern_alerts: pattern_count, total: total}
  end

  # Mark an alert as read
  def mark_read(alert_id)
    alert = RiskAlert.find(alert_id)
    alert.update!(is_read: true)
    alert
  end

  # Mark all alerts as read
  def mark_all_read
    RiskAlert.where(is_read: false).update_all(is_read: true)
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  def create_transaction_alert(transaction)
    alert_type = determine_alert_type(transaction)

    RiskAlert.create!(
      alert_type: alert_type,
      related_transaction_id: transaction.id,
      related_address: transaction.from_address,
      risk_score: transaction.anomaly_score,
      description: build_transaction_description(transaction, alert_type),
      is_read: false
    )
  end

  def create_pattern_alert(pattern)
    RiskAlert.create!(
      alert_type: pattern.pattern_type,
      related_transaction_id: nil,
      related_address: pattern.address,
      risk_score: pattern.confidence,
      description: build_pattern_description(pattern),
      is_read: false
    )
  end

  def determine_alert_type(transaction)
    if transaction.value >= HIGH_VALUE_THRESHOLD_WEI
      "high_value"
    elsif transaction.from_address == transaction.to_address
      "circular_transfer"
    else
      "suspicious_transaction"
    end
  end

  def build_transaction_description(transaction, alert_type)
    value_eth = (transaction.value / 1e18).round(4)
    case alert_type
    when "high_value"
      "High value transfer of #{value_eth} ETH detected from #{transaction.from_address[0..10]}..."
    when "circular_transfer"
      "Circular transfer detected — address sending to itself: #{transaction.from_address[0..10]}..."
    else
      "Suspicious transaction with anomaly score #{transaction.anomaly_score}: #{transaction.tx_hash[0..20]}..."
    end
  end

  def build_pattern_description(pattern)
    data = pattern.pattern_data
    case pattern.pattern_type
    when "rapid_transfers"
      "#{data['transfer_count']} transfers in #{data['window_minutes']} minutes from #{pattern.address[0..10]}..."
    when "dormant_activation"
      "Wallet dormant for #{data['dormant_days']} days suddenly activated: #{pattern.address[0..10]}..."
    when "fan_out"
      "Address distributing to #{data['unique_recipients']} unique addresses in #{data['window_hours']} hours: #{pattern.address[0..10]}..."
    when "fan_in"
      "#{data['unique_senders']} addresses collecting funds to single address: #{pattern.address[0..10]}..."
    else
      "Suspicious pattern detected (#{pattern.pattern_type}) for #{pattern.address[0..10]}..."
    end
  end

  def alert_exists_for_pattern?(pattern)
    RiskAlert.exists?(
      alert_type: pattern.pattern_type,
      related_address: pattern.address
    )
  end
end
