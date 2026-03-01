# frozen_string_literal: true

class AnalyzeTransactionsJob < ApplicationJob
  queue_as :default

  # ============================================================================
  # Runs the full analysis pipeline on stored transactions:
  #   1. Score any unscored transactions
  #   2. Detect patterns in recent activity
  #   3. Generate alerts for anything suspicious
  # ============================================================================

  def perform
    Rails.logger.info "Starting AnalyzeTransactionsJob at #{Time.current}"

    begin
      # Step 1: Score unscored transactions
      scoring_results = RiskScoringService.new.score_pending_transactions
      Rails.logger.info "Scored #{scoring_results.count} transactions"

      # Step 2: Detect patterns in recent activity
      pattern_results = PatternDetectionService.new.analyze_recent_activity(hours: 1)
      Rails.logger.info "Found patterns in #{pattern_results.count} addresses"

      # Step 3: Generate alerts
      alert_results = AlertService.new.run
      Rails.logger.info "Alert results: #{alert_results}"

    rescue StandardError => e
      Rails.logger.error("AnalyzeTransactionsJob failed: #{e.message}")
      raise e
    end
  end
end
