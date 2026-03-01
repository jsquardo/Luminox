# frozen_string_literal: true

class UpdateAddressMetricsJob < ApplicationJob
  queue_as :default

  # ============================================================================
  # Periodically recalculates address-level metrics and risk scores.
  # Runs every 5-10 minutes to keep address data fresh.
  # ============================================================================

  def perform
    Rails.logger.info "Starting UpdateAddressMetricsJob at #{Time.current}"

    begin
      scorer = RiskScoringService.new
      updated = 0

      # Only update addresses that have had recent transaction activity
      active_addresses = Address.where("last_seen > ?", 1.hour.ago)
      Rails.logger.info "Updating #{active_addresses.count} recently active addresses"

      active_addresses.find_each do |address|
        scorer.score_address(address)
        updated += 1
      end

      Rails.logger.info "UpdateAddressMetricsJob complete — updated #{updated} addresses"

    rescue StandardError => e
      Rails.logger.error("UpdateAddressMetricsJob failed: #{e.message}")
      raise e
    end
  end
end
