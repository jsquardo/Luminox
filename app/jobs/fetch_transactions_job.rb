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
      service = BlockchainService.new
      transactions = service.fetch_recent_transactions(limit: 50)

      if transactions.empty?
        Rails.logger.warn "No transactions found in this fetch"
        return
      end

      Rails.logger.info "Fetched #{transactions.count} transactions"

      result = TransactionProcessor.new.process_transactions(transactions)
      Rails.logger.info "Processing results: #{result}"

    rescue StandardError => e
      Rails.logger.error("FetchTransactionsJob failed: #{e.message}")
      raise e
    end
  end
end
