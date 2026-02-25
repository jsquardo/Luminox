# frozen_string_literal: true

class TransactionProcessor
  # ============================================================================
  # This service processes raw transaction data from the blockchain.
  # It is the central hub of the data pipeline:
  #
  #   BlockchainService → TransactionProcessor → Database
  #                                            → RiskScoringService (soon)
  #                                            → PatternDetectionService (soon)
  #                                            → AlertService (soon)
  # ============================================================================

  def initialize
    @processed_count = 0
    @skipped_count = 0
    @error_count = 0
  end

  # ============================================================================
  # PUBLIC METHODS
  # ============================================================================

  # Process a collection of raw transactions from the blockchain
  def process_transactions(raw_transactions)
    return if raw_transactions.blank?

    raw_transactions.each do |tx_data|
      process_single(tx_data)
    end

    log_summary
    {processed: @processed_count, skipped: @skipped_count, errors: @error_count}
  end

  # process a single raw transaction
  def process_single(tx_data)
    return if tx_data.nil?
    return if tx_data[:tx_hash].nil?

    # Skip if already stored
    if Transaction.exists?(tx_hash: tx_data[:tx_hash])
      @skipped_count += 1
      return
    end

    ActiveRecord::Base.transaction do
      transaction = store_transaction(tx_data)
      return unless transaction

      ensure_address_exists(tx_data[:from_address])
      ensure_address_exists(tx_data[:to_address])
      update_address_metrics(tx_data)
    end

    # Trigger risk scoring for the addresses involved
    scorer = RiskScoringService.new
    addr_from = Address.find_by(address: tx_data[:from_address])
    addr_to = Address.find_by(address: tx_data[:to_address])
    scorer.score_address(addr_from) if addr_from
    scorer.score_address(addr_to) if addr_to
    @processed_count += 1
  rescue StandardError => e
    @error_count += 1
    Rails.logger.error("TransactionProcessor error for #{tx_data[:tx_hash]}: #{e.message}")
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  def store_transaction(tx_data)
    Transaction.create!(
      tx_hash: tx_data[:tx_hash],
      from_address: tx_data[:from_address],
      to_address: tx_data[:to_address],
      value: tx_data[:value] || 0,
      gas_price: tx_data[:gas_price] || 0,
      block_number: tx_data[:block_number] || 0,
      timestamp: tx_data[:timestamp] || Time.current,
      is_contract_interaction: tx_data[:is_contract_interaction] || false,
      anomaly_score: 0.0,
      is_alerted: false
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Failed to store transaction #{tx_data[:tx_hash]}: #{e.message}")
    nil
  end

  def ensure_address_exists(address)
    return if address.nil?
    return unless address.match?(/\A0x[a-fA-F0-9]{40}\z/)

    Address.find_or_create_by(address: address) do |a|
      a.risk_score = 0.0
      a.transaction_count = 0
      a.total_sent = 0
      a.total_received = 0
      a.is_contract = false
      a.first_seen = Time.current
      a.last_seen = Time.current
    end
  end

  def update_address_metrics(tx_data)
    update_sender_metrics(tx_data[:from_address], tx_data[:value])
    update_receiver_metrics(tx_data[:to_address], tx_data[:value])
  end

  def update_sender_metrics(address, value)
    return if address.nil?

    addr = Address.find_by(address: address)
    return unless addr

    addr.increment!(:transaction_count)
    addr.increment!(:total_sent, value || 0)
    addr.update!(last_seen: Time.current)
  end

  def update_receiver_metrics(address, value)
    return if address.nil?

    addr = Address.find_by(address: address)
    return unless addr

    addr.increment!(:transaction_count)
    addr.increment!(:total_received, value || 0)
    addr.update!(last_seen: Time.current)
  end

  def log_summary
    Rails.logger.info(
      "TransactionProcessor complete — " \
      "processed: #{@processed_count}, " \
      "skipped: #{@skipped_count}, " \
      "errors: #{@error_count}"
    )
  end
end
