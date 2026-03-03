# frozen_string_literal: true

class AlertsController < InertiaController
  include ActionView::Helpers::DateHelper

  def index
    alerts = RiskAlert.all

    # ── Filtering ───────────────────────────────────────────────
    alerts = alerts.where(is_read: false) if params[:status] == "unread"
    alerts = alerts.where(is_read: true)  if params[:status] == "read"

    alerts = case params[:severity]
    when "critical" then alerts.where("risk_score >= ?", 80)
    when "high"     then alerts.where("risk_score >= ? AND risk_score < ?", 60, 80)
    when "medium"   then alerts.where("risk_score >= ? AND risk_score < ?", 40, 60)
    when "low"      then alerts.where("risk_score < ?", 40)
    else alerts
    end

    alerts = alerts.by_type(params[:type]) if params[:type].present? && params[:type] != "all"

    # ── Sorting ─────────────────────────────────────────────────
    alerts = case params[:sort]
    when "oldest"    then alerts.order(created_at: :asc)
    when "risk_asc"  then alerts.order(risk_score: :asc)
    when "risk_desc" then alerts.order(risk_score: :desc)
    else alerts.order(created_at: :desc)
    end

    # ── Pagination ───────────────────────────────────────────────
    page     = (params[:page] || 1).to_i
    per_page = 20
    total    = alerts.count
    alerts   = alerts.limit(per_page).offset((page - 1) * per_page)

    serialized = alerts.map do |alert|
      {
        id:            alert.id,
        alert_type:    alert.alert_type,
        risk_score:    alert.risk_score.round,
        address:       alert.related_address,
        short_address: "#{alert.related_address[0..5]}...#{alert.related_address[-4..]}",
        description:   alert.description,
        is_read:       alert.is_read,
        critical:      alert.critical?,
        severity:      severity_label(alert.risk_score),
        time_ago:      time_ago_in_words(alert.created_at) + " ago",
        created_at:    alert.created_at.strftime("%b %d, %Y %H:%M")
      }
    end

    summary = {
      total:    RiskAlert.count,
      unread:   RiskAlert.unread.count,
      critical: RiskAlert.where("risk_score >= ?", 80).count,
      high:     RiskAlert.where("risk_score >= ? AND risk_score < ?", 60, 80).count
    }

    alert_types = RiskAlert.distinct.pluck(:alert_type).sort

    render inertia: "alerts/index", props: {
      alerts:      serialized,
      summary:     summary,
      alert_types: alert_types,
      pagination:  {
        page:        page,
        per_page:    per_page,
        total:       total,
        total_pages: (total.to_f / per_page).ceil
      },
      filters: {
        status:   params[:status] || "all",
        severity: params[:severity] || "all",
        type:     params[:type] || "all",
        sort:     params[:sort] || "newest"
      }
    }
  end

  def mark_read
    alert = RiskAlert.find(params[:id])
    alert.mark_as_read!
    redirect_to alerts_path, notice: "Alert marked as read."
  end

  def mark_all_read
    RiskAlert.unread.update_all(is_read: true)
    redirect_to alerts_path, notice: "All alerts marked as read."
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
