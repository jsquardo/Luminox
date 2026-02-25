# frozen_string_literal: true

class RiskScoringService
  # ============================================================================
  # Analyzes transactions and addresses to calculate risk scores (0-100).
  # Higher score = more suspicious.
  #
  # Scoring factors:
  #   - High value transaction (whale movement)
  #   - Circular transfer (sending to yourself)
  #   - Dormant wallet activation (inactive wallet suddenly moves funds)
  #   - Rapid successive transfers (bot-like behavior)
  #   - New wallet moving large amounts (no history)
  #   - Contract interactions with high value
  # ============================================================================

  # Thresholds
  WHALE_THRESHOLD_ETH = 100  # 100 ETH
  WHALE_THRESHOLD_WEI = (WHALE_THRESHOLD_ETH * 1e18).to_i
  DORMANCY_THRESHOLD_DAYS = 30
  RAPID_TRANSFER_WINDOW = 10.minutes
  RAPID_TRANSFER_COUNT = 5
  NEW_WALLET_TX_THRESHOLD = 3  # fewer than this = "new wallet"

  # Score weights (must add up to 100)
  WEIGHTS = {
    high_value: 25,
    circular_transfer: 20,
    dormant_activation: 20,
    rapid_transfers: 15,
    new_wallet_large_transfer: 15,
    contract_interaction_high_value: 5
  }.freeze

  def initialize
    @reasons = []
  end

  # ============================================================================
  # PUBLIC METHODS
  # ============================================================================

  # Score a single transaction (0-100)
  def score_transaction(transaction)
    @reasons = []
    score = 0

    score += check_high_value(transaction)
    score += check_circular_transfer(transaction)
    score += check_dormant_activation(transaction)
    score += check_rapid_transfers(transaction)
    score += check_new_wallet_large_transfer(transaction)
    score += check_contract_interaction_high_value(transaction)

    final_score = [score, 100].min

    transaction.update!(anomaly_score: final_score)

    Rails.logger.debug(
      "Risk score for #{transaction.tx_hash}: #{final_score} — reasons: #{@reasons.join(', ')}"
    )

    {score: final_score, reasons: @reasons}
  end

  # Score all unscored transactions
  def score_pending_transactions
    transactions = Transaction.where(anomaly_score: 0.0).where(is_alerted: false)
    results = transactions.map { |tx| score_transaction(tx) }
    Rails.logger.info "RiskScoringService scored #{results.count} transactions"
    results
  end

  # Recalculate risk score for a specific address based on its transactions
  def score_address(address_record)
    transactions = Transaction.where(
      "from_address = ? OR to_address = ?",
      address_record.address,
      address_record.address
    )

    return 0.0 if transactions.empty?

    # Address risk is the average of its top 3 highest transaction scores
    top_scores = transactions.order(anomaly_score: :desc).limit(3).pluck(:anomaly_score)
    avg_score = top_scores.sum / top_scores.size.to_f

    address_record.update!(risk_score: avg_score.round(2))
    avg_score
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  # Large ETH transfers are inherently higher risk
  def check_high_value(transaction)
    return 0 unless transaction.value >= WHALE_THRESHOLD_WEI

    @reasons << "high_value"
    WEIGHTS[:high_value]
  end

  # Sending to yourself is a classic mixing/obfuscation technique
  def check_circular_transfer(transaction)
    return 0 unless transaction.from_address == transaction.to_address

    @reasons << "circular_transfer"
    WEIGHTS[:circular_transfer]
  end

  # A wallet that was dormant for 30+ days suddenly moving funds is suspicious
  def check_dormant_activation(transaction)
    address = Address.find_by(address: transaction.from_address)
    return 0 unless address

    # Find the previous transaction from this address before this one
    previous_tx = Transaction.where(from_address: transaction.from_address)
                             .where("timestamp < ?", transaction.timestamp)
                             .order(timestamp: :desc)
                             .first

    return 0 unless previous_tx

    days_dormant = (transaction.timestamp - previous_tx.timestamp) / 1.day
    return 0 unless days_dormant >= DORMANCY_THRESHOLD_DAYS

    @reasons << "dormant_activation"
    WEIGHTS[:dormant_activation]
  end

  # Many transfers in a short window suggests bot activity
  def check_rapid_transfers(transaction)
    window_start = transaction.timestamp - RAPID_TRANSFER_WINDOW

    recent_count = Transaction.where(from_address: transaction.from_address)
                              .where("timestamp BETWEEN ? AND ?", window_start, transaction.timestamp)
                              .count

    return 0 unless recent_count >= RAPID_TRANSFER_COUNT

    @reasons << "rapid_transfers"
    WEIGHTS[:rapid_transfers]
  end

  # A brand new wallet moving large amounts is suspicious
  def check_new_wallet_large_transfer(transaction)
    return 0 unless transaction.value >= WHALE_THRESHOLD_WEI

    address = Address.find_by(address: transaction.from_address)
    return 0 unless address
    return 0 unless address.transaction_count <= NEW_WALLET_TX_THRESHOLD

    @reasons << "new_wallet_large_transfer"
    WEIGHTS[:new_wallet_large_transfer]
  end

  # High value contract interactions could be flash loans or exploits
  def check_contract_interaction_high_value(transaction)
    return 0 unless transaction.is_contract_interaction
    return 0 unless transaction.value >= WHALE_THRESHOLD_WEI

    @reasons << "contract_interaction_high_value"
    WEIGHTS[:contract_interaction_high_value]
  end
end
