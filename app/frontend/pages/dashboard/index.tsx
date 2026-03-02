import { Head } from "@inertiajs/react"
import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  CheckCircle2,
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
type ThreatStatus = "active" | "investigating" | "resolved"

interface StatCard {
  label: string
  value: string
  delta: string
  trend: "up" | "down" | "neutral"
  positive: boolean
  icon: React.ElementType
  glow?: "red" | "teal" | "none"
}

interface ThreatEvent {
  id: string
  type: string
  source: string
  target: string
  severity: Severity
  status: ThreatStatus
  time: string
}

// ── Mock Data ──────────────────────────────────────────────────────
const stats: StatCard[] = [
  {
    label: "Active Threats",
    value: "14",
    delta: "+3 since yesterday",
    trend: "up",
    positive: false,
    icon: AlertTriangle,
    glow: "red",
  },
  {
    label: "Incidents Resolved",
    value: "127",
    delta: "+12 this week",
    trend: "up",
    positive: true,
    icon: CheckCircle2,
    glow: "teal",
  },
  {
    label: "Network Nodes",
    value: "2,841",
    delta: "98.7% healthy",
    trend: "neutral",
    positive: true,
    icon: Globe,
    glow: "none",
  },
  {
    label: "Avg Response Time",
    value: "4.2m",
    delta: "-0.8m from baseline",
    trend: "down",
    positive: true,
    icon: Clock,
    glow: "none",
  },
]

const recentThreats: ThreatEvent[] = [
  {
    id: "THR-0091",
    type: "SQL Injection Attempt",
    source: "185.220.101.45",
    target: "api.luminox.internal",
    severity: "critical",
    status: "active",
    time: "2m ago",
  },
  {
    id: "THR-0090",
    type: "Brute Force Auth",
    source: "91.108.4.12",
    target: "admin.luminox.internal",
    severity: "high",
    status: "investigating",
    time: "11m ago",
  },
  {
    id: "THR-0089",
    type: "Port Scan",
    source: "10.0.4.22",
    target: "172.16.0.0/24",
    severity: "medium",
    status: "resolved",
    time: "34m ago",
  },
  {
    id: "THR-0088",
    type: "Malware Signature",
    source: "downloads.cdn.xyz",
    target: "workstation-14",
    severity: "high",
    status: "resolved",
    time: "1h ago",
  },
  {
    id: "THR-0087",
    type: "Anomalous Traffic",
    source: "192.168.1.110",
    target: "external egress",
    severity: "low",
    status: "resolved",
    time: "2h ago",
  },
]

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

function statusConfig(s: ThreatStatus) {
  switch (s) {
    case "active":
      return { label: "Active", dot: "lx-dot-critical" }
    case "investigating":
      return { label: "Investigating", dot: "lx-dot-warning" }
    case "resolved":
      return { label: "Resolved", dot: "lx-dot-active" }
  }
}

// ── Component ──────────────────────────────────────────────────────
export default function Dashboard() {
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
          {stats.map((stat, i) => (
            <StatCardComponent key={stat.label} stat={stat} delay={i + 1} />
          ))}
        </div>

        {/* ── Main content row ─────────────────────────────── */}
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">

          {/* Threat feed — 2 cols */}
          <div className="lx-fade-in lx-delay-5 lx-card col-span-1 lg:col-span-2">
            <div className="flex items-center justify-between border-b border-border px-5 py-4">
              <div className="flex items-center gap-2">
                <Radio className="size-4 text-primary" strokeWidth={1.5} />
                <h2 className="font-display text-sm font-semibold">Recent Threats</h2>
              </div>
              <button className="flex items-center gap-1 text-xs text-muted-foreground transition-colors hover:text-foreground">
                View all <ChevronRight className="size-3" />
              </button>
            </div>
            <div className="divide-y divide-border/50">
              {recentThreats.map((threat) => {
                const sev = severityConfig(threat.severity)
                const sta = statusConfig(threat.status)
                return (
                  <div
                    key={threat.id}
                    className="group flex items-center gap-4 px-5 py-3 transition-colors hover:bg-sidebar-accent/40"
                  >
                    <span className={sta.dot} />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-body text-xs font-medium text-muted-foreground">
                          {threat.id}
                        </span>
                        <span
                          className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${sev.className}`}
                        >
                          {sev.label}
                        </span>
                      </div>
                      <p className="mt-0.5 truncate font-body text-sm font-medium text-foreground">
                        {threat.type}
                      </p>
                      <p className="truncate text-xs text-muted-foreground">
                        {threat.source} → {threat.target}
                      </p>
                    </div>
                    <div className="flex flex-col items-end gap-1 text-right">
                      <span className="text-xs text-muted-foreground">{threat.time}</span>
                      <span className="text-[10px] font-medium text-muted-foreground/70">
                        {sta.label}
                      </span>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* System health sidebar */}
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
                <span className="font-display text-5xl font-bold lx-gradient-text">72</span>
                <span className="mb-1 font-body text-sm font-medium text-muted-foreground">/ 100</span>
              </div>
              <div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-secondary">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-primary/80 to-primary"
                  style={{ width: "72%" }}
                />
              </div>
              <p className="mt-2 text-xs text-muted-foreground">Elevated — immediate review recommended</p>
            </div>

            {/* Detection breakdown */}
            <div className="lx-fade-in lx-delay-5 lx-card p-5">
              <div className="mb-4 flex items-center gap-2">
                <Activity className="size-4 text-accent" strokeWidth={1.5} />
                <h3 className="font-display text-sm font-semibold">Detections Today</h3>
              </div>
              <div className="space-y-3">
                {[
                  { label: "Intrusion", value: 38, color: "bg-primary" },
                  { label: "Malware", value: 24, color: "bg-accent" },
                  { label: "Phishing", value: 19, color: "bg-yellow-500" },
                  { label: "Other", value: 11, color: "bg-muted-foreground" },
                ].map((item) => (
                  <div key={item.label} className="space-y-1">
                    <div className="flex justify-between text-xs">
                      <span className="text-muted-foreground">{item.label}</span>
                      <span className="font-medium text-foreground">{item.value}%</span>
                    </div>
                    <div className="h-1 w-full overflow-hidden rounded-full bg-secondary">
                      <div
                        className={`h-full rounded-full ${item.color} opacity-80`}
                        style={{ width: `${item.value}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick actions */}
            <div className="lx-fade-in lx-delay-5 lx-card overflow-hidden">
              <div className="border-b border-border px-5 py-3">
                <h3 className="font-display text-sm font-semibold">Quick Actions</h3>
              </div>
              {[
                { label: "Run Vulnerability Scan", icon: Shield },
                { label: "Export Incident Report", icon: ArrowUpRight },
                { label: "Review Alert Rules", icon: AlertTriangle },
              ].map(({ label, icon: Icon }) => (
                <button
                  key={label}
                  className="group flex w-full items-center justify-between px-5 py-3 text-sm text-muted-foreground transition-colors hover:bg-sidebar-accent/50 hover:text-foreground"
                >
                  <div className="flex items-center gap-3">
                    <Icon className="size-4 text-muted-foreground group-hover:text-primary" strokeWidth={1.5} />
                    <span className="font-body font-medium">{label}</span>
                  </div>
                  <ChevronRight className="size-3 opacity-0 transition-opacity group-hover:opacity-100" />
                </button>
              ))}
            </div>

          </div>
        </div>
      </div>
    </AppLayout>
  )
}

// ── StatCard sub-component ─────────────────────────────────────────
function StatCardComponent({ stat, delay }: { stat: StatCard; delay: number }) {
  const glowClass =
    stat.glow === "red"
      ? "lx-card-glow-red"
      : stat.glow === "teal"
        ? "lx-card-glow-teal"
        : "lx-card"

  return (
    <div className={`lx-fade-in lx-delay-${delay} ${glowClass} p-5`}>
      <div className="flex items-start justify-between">
        <span className="font-body text-xs font-semibold uppercase tracking-widest text-muted-foreground">
          {stat.label}
        </span>
        <div className="flex size-8 items-center justify-center rounded-lg bg-secondary">
          <stat.icon className="size-4 text-muted-foreground" strokeWidth={1.5} />
        </div>
      </div>
      <div className="mt-3">
        <span className="font-display text-3xl font-bold text-foreground">{stat.value}</span>
      </div>
      <div className="mt-2 flex items-center gap-1.5">
        {stat.trend === "up" && (
          <TrendingUp
            className={`size-3 ${stat.positive ? "text-emerald-400" : "text-red-400"}`}
          />
        )}
        {stat.trend === "down" && (
          <TrendingDown
            className={`size-3 ${stat.positive ? "text-emerald-400" : "text-red-400"}`}
          />
        )}
        <span className="font-body text-xs text-muted-foreground">{stat.delta}</span>
      </div>
    </div>
  )
}
