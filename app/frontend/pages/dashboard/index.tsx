import { Head, usePage } from "@inertiajs/react"
import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  ChevronRight,
  Clock,
  Globe,
  Radio,
  Shield,
  TrendingDown,
  TrendingUp,
  Zap,
} from "lucide-react"

import AppLayout from "@/layouts/app-layout"
import { dashboardPath } from "@/routes"
import type { BreadcrumbItem } from "@/types"

const breadcrumbs: BreadcrumbItem[] = [
  { title: "Dashboard", href: dashboardPath() },
]

// ── Types ──────────────────────────────────────────────────────────
type Severity = "critical" | "high" | "medium" | "low"
type Trend = "up" | "down" | "neutral"

interface DashboardStats {
  active_threats: number
  incidents_resolved: number
  high_risk_addresses: number
  avg_anomaly_score: number
}

interface RecentAlert {
  id: number
  alert_type: string
  risk_score: number
  address: string
  description: string
  is_read: boolean
  critical: boolean
  severity: Severity
  status: "active" | "resolved"
  time_ago: string
}

interface DetectionItem {
  label: string
  count: number
  percentage: number
}

interface RiskAddress {
  address: string
  short_address: string
  risk_score: number
  transaction_count: number
  label: string | null
  last_seen: string
}

interface DashboardProps {
  stats: DashboardStats
  threat_score: number
  recent_alerts: RecentAlert[]
  detection_breakdown: DetectionItem[]
  top_risk_addresses: RiskAddress[]
  unread_count: number
}

// ── Helpers ────────────────────────────────────────────────────────
function severityConfig(s: Severity) {
  switch (s) {
    case "critical":
      return { label: "Critical", className: "bg-red-500/15 text-red-400 border border-red-500/30" }
    case "high":
      return { label: "High", className: "bg-orange-500/15 text-orange-400 border border-orange-500/30" }
    case "medium":
      return { label: "Medium", className: "bg-yellow-500/15 text-yellow-400 border border-yellow-500/30" }
    case "low":
      return { label: "Low", className: "bg-blue-500/15 text-blue-400 border border-blue-500/30" }
  }
}

function statusDot(status: string) {
  switch (status) {
    case "active":        return "lx-dot-critical"
    case "investigating": return "lx-dot-warning"
    default:              return "lx-dot-active"
  }
}

function threatScoreColor(score: number) {
  if (score >= 80) return "oklch(0.62 0.22 28)"
  if (score >= 60) return "oklch(0.78 0.14 60)"
  return "oklch(0.65 0.14 195)"
}

function threatScoreLabel(score: number) {
  if (score >= 80) return "Critical — immediate action required"
  if (score >= 60) return "Elevated — immediate review recommended"
  if (score >= 40) return "Moderate — monitor closely"
  return "Low — all systems nominal"
}

// ── Component ──────────────────────────────────────────────────────
export default function Dashboard() {
  const page = usePage()
  const {
    stats,
    threat_score,
    recent_alerts,
    detection_breakdown,
    top_risk_addresses,
  } = page.props as unknown as DashboardProps

  const statCards = [
    {
      label: "Active Threats",
      value: stats?.active_threats ?? 0,
      delta: "Unresolved alerts",
      trend: "up" as Trend,
      positive: false,
      icon: AlertTriangle,
      glow: "red" as const,
    },
    {
      label: "Incidents Resolved",
      value: stats?.incidents_resolved ?? 0,
      delta: "All time",
      trend: "up" as Trend,
      positive: true,
      icon: Shield,
      glow: "teal" as const,
    },
    {
      label: "High Risk Addresses",
      value: stats?.high_risk_addresses ?? 0,
      delta: "Risk score ≥ 70",
      trend: "neutral" as Trend,
      positive: false,
      icon: Globe,
      glow: "none" as const,
    },
    {
      label: "Avg Anomaly Score",
      value: `${stats?.avg_anomaly_score ?? 0}`,
      delta: "Last 24 hours",
      trend: "neutral" as Trend,
      positive: true,
      icon: Clock,
      glow: "none" as const,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Dashboard" />

      <div className="lx-grid-bg flex flex-1 flex-col gap-6 p-6">

        {/* ── Page header ──────────────────────────────────── */}
        <div className="lx-fade-in flex items-start justify-between">
          <div>
            <h1 className="font-display text-2xl font-semibold text-foreground">
              Security Overview
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Real-time threat intelligence — last updated just now
            </p>
          </div>
          <div className="flex items-center gap-2 rounded-lg border border-border bg-card px-3 py-2">
            <span className="lx-dot-active" />
            <span className="font-body text-xs font-medium text-muted-foreground">Live</span>
          </div>
        </div>

        {/* ── Stat cards ───────────────────────────────────── */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {statCards.map((stat, i) => {
            const glowClass =
              stat.glow === "red"  ? "lx-card-glow-red"  :
              stat.glow === "teal" ? "lx-card-glow-teal" : "lx-card"
            return (
              <div key={stat.label} className={`lx-fade-in lx-delay-${i + 1} ${glowClass} p-5`}>
                <div className="flex items-start justify-between">
                  <span className="font-body text-xs font-semibold uppercase tracking-widest text-muted-foreground">
                    {stat.label}
                  </span>
                  <div className="flex size-8 items-center justify-center rounded-lg bg-secondary">
                    <stat.icon className="size-4 text-muted-foreground" strokeWidth={1.5} />
                  </div>
                </div>
                <div className="mt-3">
                  <span className="font-display text-3xl font-bold text-foreground">
                    {String(stat.value).toLocaleString()}
                  </span>
                </div>
                <div className="mt-2 flex items-center gap-1.5">
                  {stat.trend === "up" && (
                    <TrendingUp className={`size-3 ${stat.positive ? "text-emerald-400" : "text-red-400"}`} />
                  )}
                  {stat.trend === "down" && (
                    <TrendingDown className={`size-3 ${stat.positive ? "text-emerald-400" : "text-red-400"}`} />
                  )}
                  <span className="font-body text-xs text-muted-foreground">{stat.delta}</span>
                </div>
              </div>
            )
          })}
        </div>

        {/* ── Main content row ─────────────────────────────── */}
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">

          {/* Recent alerts feed — 2 cols */}
          <div className="lx-fade-in lx-delay-5 lx-card col-span-1 lg:col-span-2">
            <div className="flex items-center justify-between border-b border-border px-5 py-4">
              <div className="flex items-center gap-2">
                <Radio className="size-4 text-primary" strokeWidth={1.5} />
                <h2 className="font-display text-sm font-semibold">Recent Alerts</h2>
              </div>
              <a href="/alerts" className="flex items-center gap-1 text-xs text-muted-foreground transition-colors hover:text-foreground">
                View all <ChevronRight className="size-3" />
              </a>
            </div>

            {recent_alerts?.length > 0 ? (
              <div className="divide-y divide-border/50">
                {recent_alerts.map((alert) => {
                  const sev = severityConfig(alert.severity)
                  return (
                    <div
                      key={alert.id}
                      className="group flex items-center gap-4 px-5 py-3 transition-colors hover:bg-sidebar-accent/40"
                    >
                      <span className={statusDot(alert.status)} />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-body text-xs font-medium text-muted-foreground">
                            #{alert.id}
                          </span>
                          <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${sev.className}`}>
                            {sev.label}
                          </span>
                          <span className="text-[10px] font-medium text-muted-foreground/60">
                            Score: {alert.risk_score}
                          </span>
                        </div>
                        <p className="mt-0.5 truncate font-body text-sm font-medium text-foreground">
                          {alert.alert_type.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())}
                        </p>
                        <p className="truncate text-xs text-muted-foreground">
                          {alert.address.slice(0, 6)}...{alert.address.slice(-4)}
                        </p>
                      </div>
                      <div className="flex flex-col items-end gap-1 text-right">
                        <span className="text-xs text-muted-foreground">{alert.time_ago}</span>
                        <span className="text-[10px] font-medium capitalize text-muted-foreground/70">
                          {alert.status}
                        </span>
                      </div>
                    </div>
                  )
                })}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center py-16 text-muted-foreground">
                <Shield className="mb-3 size-8 opacity-30" strokeWidth={1} />
                <p className="text-sm font-medium">No recent alerts</p>
                <p className="text-xs opacity-60">All systems clear</p>
              </div>
            )}
          </div>

          {/* Right column */}
          <div className="flex flex-col gap-4">

            {/* Threat score */}
            <div className="lx-fade-in lx-delay-5 lx-card-glow-red p-5">
              <div className="flex items-center gap-2 text-muted-foreground">
                <Zap className="size-4 text-primary" strokeWidth={1.5} />
                <span className="font-body text-xs font-semibold uppercase tracking-widest">
                  Threat Score
                </span>
              </div>
              <div className="mt-3 flex items-end justify-between">
                <span
                  className="font-display text-5xl font-bold"
                  style={{ color: threatScoreColor(threat_score ?? 0) }}
                >
                  {threat_score ?? 0}
                </span>
                <span className="mb-1 font-body text-sm font-medium text-muted-foreground">/ 100</span>
              </div>
              <div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-secondary">
                <div
                  className="h-full rounded-full transition-all duration-700"
                  style={{
                    width: `${threat_score ?? 0}%`,
                    background: `linear-gradient(90deg, ${threatScoreColor(threat_score ?? 0)}80, ${threatScoreColor(threat_score ?? 0)})`,
                  }}
                />
              </div>
              <p className="mt-2 text-xs text-muted-foreground">
                {threatScoreLabel(threat_score ?? 0)}
              </p>
            </div>

            {/* Detection breakdown */}
            <div className="lx-fade-in lx-delay-5 lx-card p-5">
              <div className="mb-4 flex items-center gap-2">
                <Activity className="size-4 text-accent" strokeWidth={1.5} />
                <h3 className="font-display text-sm font-semibold">Detections Today</h3>
              </div>
              {detection_breakdown?.length > 0 ? (
                <div className="space-y-3">
                  {detection_breakdown.map((item, i) => {
                    const colors = ["bg-primary", "bg-accent", "bg-yellow-500", "bg-purple-500", "bg-blue-500"]
                    return (
                      <div key={item.label} className="space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-muted-foreground">{item.label}</span>
                          <span className="font-medium text-foreground">{item.percentage}%</span>
                        </div>
                        <div className="h-1 w-full overflow-hidden rounded-full bg-secondary">
                          <div
                            className={`h-full rounded-full ${colors[i % colors.length]} opacity-80 transition-all duration-700`}
                            style={{ width: `${item.percentage}%` }}
                          />
                        </div>
                      </div>
                    )
                  })}
                </div>
              ) : (
                <p className="py-4 text-center text-xs text-muted-foreground">No detections in last 24h</p>
              )}
            </div>

            {/* Top risk addresses */}
            <div className="lx-fade-in lx-delay-5 lx-card overflow-hidden">
              <div className="flex items-center justify-between border-b border-border px-5 py-3">
                <h3 className="font-display text-sm font-semibold">Top Risk Addresses</h3>
                <a href="/addresses" className="text-xs text-muted-foreground hover:text-foreground">
                  View all
                </a>
              </div>
              {top_risk_addresses?.length > 0 ? (
                top_risk_addresses.map((addr) => (
                  <div
                    key={addr.address}
                    className="group flex items-center justify-between px-5 py-3 transition-colors hover:bg-sidebar-accent/50"
                  >
                    <div className="min-w-0 flex-1">
                      <p className="font-mono text-xs font-medium text-foreground">
                        {addr.short_address}
                      </p>
                      <p className="text-[10px] text-muted-foreground">
                        {addr.transaction_count} txns · {addr.last_seen}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className="rounded-full px-2 py-0.5 text-[10px] font-bold"
                        style={{
                          background: `${threatScoreColor(addr.risk_score)}20`,
                          color: threatScoreColor(addr.risk_score),
                          border: `1px solid ${threatScoreColor(addr.risk_score)}40`,
                        }}
                      >
                        {addr.risk_score}
                      </span>
                      <ArrowUpRight className="size-3 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
                    </div>
                  </div>
                ))
              ) : (
                <p className="px-5 py-6 text-center text-xs text-muted-foreground">No high risk addresses</p>
              )}
            </div>

          </div>
        </div>
      </div>
    </AppLayout>
  )
}
