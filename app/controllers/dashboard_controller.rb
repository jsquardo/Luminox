# frozen_string_literal: true

class DashboardController < InertiaController
  def index
    # ── Stat cards ─────────────────────────────────────────────
    active_threats      = RiskAlert.unread.count
    incidents_resolved  = RiskAlert.read.count
    high_risk_addresses = Address.high_risk.count
    avg_anomaly_score   = Transaction.recent(24).average(:anomaly_score)&.round(1) || 0.0

    # ── Threat score (0-100) ────────────────────────────────────
    # Weighted average of unread alert risk scores, capped at 100
    threat_score = RiskAlert.unread.average(:risk_score)&.round || 0

    # ── Recent threats feed ─────────────────────────────────────
    recent_alerts = RiskAlert
      .by_risk
      .recent(48)
      .limit(8)
      .select(:id, :alert_type, :risk_score, :related_address, :related_transaction_id, :description, :is_read, :created_at)
      .map do |alert|
        {
          id:          alert.id,
          alert_type:  alert.alert_type,
          risk_score:  alert.risk_score.round,
          address:     alert.related_address,
          description: alert.description,
          is_read:     alert.is_read,
          critical:    alert.critical?,
          severity:    severity_label(alert.risk_score),
          status:      alert.is_read ? "resolved" : "active",
          time_ago:    time_ago_in_words(alert.created_at) + " ago"
        }
      end

    # ── Detection breakdown by type ─────────────────────────────
    detection_counts = RiskAlert
      .recent(24)
      .group(:alert_type)
      .count

    total_detections = detection_counts.values.sum.to_f
    detection_breakdown = detection_counts
      .sort_by { |_, count| -count }
      .first(5)
      .map do |type, count|
        {
          label:      type.humanize,
          count:      count,
          percentage: total_detections > 0 ? ((count / total_detections) * 100).round : 0
        }
      end

    # ── High risk addresses ──────────────────────────────────────
    top_risk_addresses = Address
      .high_risk
      .order(risk_score: :desc)
      .limit(5)
      .select(:id, :address, :risk_score, :transaction_count, :last_seen, :label)
      .map do |addr|
        {
          address:           addr.address,
          short_address:     "#{addr.address[0..5]}...#{addr.address[-4..]}",
          risk_score:        addr.risk_score.round,
          transaction_count: addr.transaction_count,
          label:             addr.label,
          last_seen:         addr.last_seen ? time_ago_in_words(addr.last_seen) + " ago" : "Never"
        }
      end

    # ── Unread alert count for bell icon ────────────────────────
    unread_count = RiskAlert.unread.count

    render inertia: "dashboard/index", props: {
      stats: {
        active_threats:      active_threats,
        incidents_resolved:  incidents_resolved,
        high_risk_addresses: high_risk_addresses,
        avg_anomaly_score:   avg_anomaly_score
      },
      threat_score:        threat_score,
      recent_alerts:       recent_alerts,
      detection_breakdown: detection_breakdown,
      top_risk_addresses:  top_risk_addresses,
      unread_count:        unread_count
    }
  end

  private

  def severity_label(risk_score)
    case risk_score
    when 80..100 then "critical"
    when 60..79  then "high"
    when 40..59  then "medium"
    else              "low"
    end
  end
end
