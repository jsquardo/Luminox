# frozen_string_literal: true

class FetchTransactionsJob < ApplicationJob
  queue_as :default

  # ============================================================================
  # This job runs on a schedule and continuously fetches recent Ethereum
  # transactions from the blockchain. It stores them in the database and
  # prepares them for analysis.
  # ============================================================================

  def perform
    Rails.logger.info "Starting FetchTransactionsJob at #{Time.current}"

    unless ENV["ALCHEMY_API_KEY"].present?
      Rails.logger.warn "ALCHEMY_API_KEY not set, skipping FetchTransactionsJob"
      return
    end

    begin
      # Initialize the blockchain service
      service = BlockchainService.new

      # Fetch recent transactions from the blockchain
      transactions = service.fetch_recent_transactions(limit: 50)

      if transactions.empty?
        Rails.logger.warn "No transactions found in this fetch"
        return
      end

      Rails.logger.info "Fetched #{transactions.count} transactions"

      # Process each transaction
      transactions.each do |tx_data|
        process_transaction(tx_data)
      end

      Rails.logger.info "FetchTransactionsJob completed successfully"
    rescue StandardError => e
      Rails.logger.error("FetchTransactionsJob failed: #{e.message}")
      raise e
    end
  end

  # ============================================================================
  # PRIVATE METHODS
  # ============================================================================

  private

  # Process a single transaction: store it and extract address data
  def process_transaction(tx_data)
    return if tx_data.nil?

    # Check if we've already stored this transaction (by tx_hash)
    transaction = Transaction.find_or_create_by(tx_hash: tx_data[:tx_hash]) do |t|
      t.from_address = tx_data[:from_address]
      t.to_address = tx_data[:to_address]
      t.value = tx_data[:value]
      t.gas_price = tx_data[:gas_price]
      t.block_number = tx_data[:block_number]
      t.timestamp = tx_data[:timestamp]
      t.is_contract_interaction = tx_data[:is_contract_interaction]
      t.anomaly_score = 0.0 # Will be calculated by analysis job
    end

    # Now we need to ensure the addresses exist in our database
    ensure_address_exists(tx_data[:from_address])
    ensure_address_exists(tx_data[:to_address])

    Rails.logger.debug "Processed transaction: #{tx_data[:tx_hash]}"
  end

  # Make sure an address exists in our database
  def ensure_address_exists(address)
    return if address.nil?

    Address.find_or_create_by(address: address) do |a|
      a.risk_score = 0.0
      a.transaction_count = 0
      a.total_sent = 0
      a.total_received = 0
      a.is_contract = false
    end
  end
end
