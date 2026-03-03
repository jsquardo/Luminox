import { Head, router, usePage } from "@inertiajs/react"
import {
  Bell,
  BellOff,
  CheckCheck,
  ChevronLeft,
  ChevronRight,
  Shield,
  SlidersHorizontal,
} from "lucide-react"

import AppLayout from "@/layouts/app-layout"
import { alertsPath, dashboardPath, markAllReadAlertsPath, markReadAlertPath } from "@/routes"
import type { BreadcrumbItem } from "@/types"

const breadcrumbs: BreadcrumbItem[] = [
  { title: "Dashboard", href: dashboardPath() },
  { title: "Alerts", href: alertsPath() },
]

// ── Types ──────────────────────────────────────────────────────────
type Severity = "critical" | "high" | "medium" | "low"

interface Alert {
  id: number
  alert_type: string
  risk_score: number
  address: string
  short_address: string
  description: string
  is_read: boolean
  critical: boolean
  severity: Severity
  time_ago: string
  created_at: string
}

interface Summary {
  total: number
  unread: number
  critical: number
  high: number
}

interface Pagination {
  page: number
  per_page: number
  total: number
  total_pages: number
}

interface Filters {
  status: string
  severity: string
  type: string
  sort: string
}

interface AlertsProps {
  alerts: Alert[]
  summary: Summary
  alert_types: string[]
  pagination: Pagination
  filters: Filters
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

function formatAlertType(type: string) {
  return type.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase())
}

function riskColor(score: number) {
  if (score >= 80) return "oklch(0.62 0.22 28)"
  if (score >= 60) return "oklch(0.78 0.14 60)"
  return "oklch(0.65 0.14 195)"
}

// ── Component ──────────────────────────────────────────────────────
export default function AlertsIndex() {
  const page = usePage()
  const { alerts, summary, alert_types, pagination, filters } =
    page.props as unknown as AlertsProps

  function applyFilter(key: string, value: string) {
    router.get(
      alertsPath(),
      { ...filters, [key]: value, page: 1 },
      { preserveScroll: true, preserveState: true }
    )
  }

  function markAllRead() {
    router.patch(markAllReadAlertsPath(), {}, { preserveScroll: true })
  }

  function markRead(id: number) {
    router.patch(markReadAlertPath({ id }), {}, { preserveScroll: true })
  }

  function goToPage(p: number) {
    router.get(
      alertsPath(),
      { ...filters, page: p },
      { preserveScroll: true, preserveState: true }
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Alerts" />

      <div className="lx-grid-bg flex flex-1 flex-col gap-6 p-6">

        {/* ── Page header ──────────────────────────────────── */}
        <div className="lx-fade-in flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="font-display text-2xl font-semibold text-foreground">
              Alerts
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              {summary?.unread ?? 0} unread · {summary?.total ?? 0} total
            </p>
          </div>
          {(summary?.unread ?? 0) > 0 && (
            <button
              onClick={markAllRead}
              className="flex items-center gap-2 rounded-lg border border-border bg-card px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:border-primary/40 hover:text-foreground"
            >
              <CheckCheck className="size-4" strokeWidth={1.5} />
              Mark all read
            </button>
          )}
        </div>

        {/* ── Summary cards ────────────────────────────────── */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            { label: "Total Alerts", value: summary?.total ?? 0, color: "text-foreground" },
            { label: "Unread", value: summary?.unread ?? 0, color: "text-primary" },
            { label: "Critical", value: summary?.critical ?? 0, color: "text-red-400" },
            { label: "High", value: summary?.high ?? 0, color: "text-orange-400" },
          ].map((s, i) => (
            <div key={s.label} className={`lx-fade-in lx-delay-${i + 1} lx-card p-4`}>
              <p className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">
                {s.label}
              </p>
              <p className={`mt-2 font-display text-2xl font-bold ${s.color}`}>
                {s.value.toLocaleString()}
              </p>
            </div>
          ))}
        </div>

        {/* ── Filters ──────────────────────────────────────── */}
        <div className="lx-fade-in lx-delay-3 lx-card p-4">
          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-2 text-muted-foreground">
              <SlidersHorizontal className="size-4" strokeWidth={1.5} />
              <span className="text-xs font-semibold uppercase tracking-widest">Filter</span>
            </div>

            <FilterSelect
              label="Status"
              value={filters?.status ?? "all"}
              onChange={(v) => applyFilter("status", v)}
              options={[
                { value: "all", label: "All" },
                { value: "unread", label: "Unread" },
                { value: "read", label: "Read" },
              ]}
            />

            <FilterSelect
              label="Severity"
              value={filters?.severity ?? "all"}
              onChange={(v) => applyFilter("severity", v)}
              options={[
                { value: "all", label: "All severities" },
                { value: "critical", label: "Critical (80+)" },
                { value: "high", label: "High (60-79)" },
                { value: "medium", label: "Medium (40-59)" },
                { value: "low", label: "Low (<40)" },
              ]}
            />

            <FilterSelect
              label="Type"
              value={filters?.type ?? "all"}
              onChange={(v) => applyFilter("type", v)}
              options={[
                { value: "all", label: "All types" },
                ...(alert_types ?? []).map((t) => ({
                  value: t,
                  label: formatAlertType(t),
                })),
              ]}
            />

            <FilterSelect
              label="Sort"
              value={filters?.sort ?? "newest"}
              onChange={(v) => applyFilter("sort", v)}
              options={[
                { value: "newest", label: "Newest first" },
                { value: "oldest", label: "Oldest first" },
                { value: "risk_desc", label: "Highest risk" },
                { value: "risk_asc", label: "Lowest risk" },
              ]}
            />

            {(filters?.status !== "all" || filters?.severity !== "all" || filters?.type !== "all") && (
              <button
                onClick={() => router.get(alertsPath())}
                className="text-xs text-muted-foreground underline underline-offset-2 hover:text-foreground"
              >
                Reset
              </button>
            )}
          </div>
        </div>

        {/* ── Alerts table ─────────────────────────────────── */}
        <div className="lx-fade-in lx-delay-4 lx-card overflow-hidden">
          {/* Table header */}
          <div className="grid grid-cols-[auto_1fr_auto_auto_auto_auto] items-center gap-4 border-b border-border px-5 py-3">
            <span />
            <span className="text-[10px] font-semibold uppercase tracking-widest text-muted-foreground">Alert</span>
            <span className="text-[10px] font-semibold uppercase tracking-widest text-muted-foreground">Score</span>
            <span className="hidden text-[10px] font-semibold uppercase tracking-widest text-muted-foreground sm:block">Address</span>
            <span className="text-[10px] font-semibold uppercase tracking-widest text-muted-foreground">Time</span>
            <span className="text-[10px] font-semibold uppercase tracking-widest text-muted-foreground">Action</span>
          </div>

          {alerts?.length > 0 ? (
            <div className="divide-y divide-border/50">
              {alerts.map((alert) => {
                const sev = severityConfig(alert.severity)
                return (
                  <div
                    key={alert.id}
                    className={`group grid grid-cols-[auto_1fr_auto_auto_auto_auto] items-center gap-4 px-5 py-4 transition-colors hover:bg-sidebar-accent/40 ${
                      !alert.is_read ? "bg-primary/[0.03]" : ""
                    }`}
                  >
                    {/* Read indicator */}
                    <div className="flex items-center justify-center">
                      {!alert.is_read ? (
                        <span
                          className="inline-block h-2 w-2 rounded-full"
                          style={{
                            background: "oklch(0.62 0.22 28)",
                            boxShadow: "0 0 6px oklch(0.62 0.22 28 / 0.6)",
                          }}
                        />
                      ) : (
                        <span className="inline-block h-2 w-2 rounded-full bg-border" />
                      )}
                    </div>

                    {/* Alert info */}
                    <div className="min-w-0">
                      <div className="mb-1 flex flex-wrap items-center gap-2">
                        <span className="font-body text-xs text-muted-foreground">#{alert.id}</span>
                        <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ${sev.className}`}>
                          {sev.label}
                        </span>
                        <span className="rounded-full border border-border bg-secondary px-2 py-0.5 text-[10px] text-muted-foreground">
                          {formatAlertType(alert.alert_type)}
                        </span>
                      </div>
                      <p className="truncate text-sm font-medium text-foreground">
                        {alert.description}
                      </p>
                    </div>

                    {/* Risk score */}
                    <div className="text-center">
                      <span
                        className="font-display text-lg font-bold"
                        style={{ color: riskColor(alert.risk_score) }}
                      >
                        {alert.risk_score}
                      </span>
                    </div>

                    {/* Address */}
                    <div className="hidden sm:block">
                      <span className="font-mono text-xs text-muted-foreground">
                        {alert.short_address}
                      </span>
                    </div>

                    {/* Time */}
                    <div className="text-right">
                      <span className="text-xs text-muted-foreground">{alert.time_ago}</span>
                    </div>

                    {/* Action */}
                    <div>
                      {!alert.is_read ? (
                        <button
                          onClick={() => markRead(alert.id)}
                          className="flex items-center gap-1 rounded-md border border-border px-2 py-1 text-[10px] font-medium text-muted-foreground opacity-0 transition-all hover:border-primary/40 hover:text-foreground group-hover:opacity-100"
                        >
                          <BellOff className="size-3" strokeWidth={1.5} />
                          Dismiss
                        </button>
                      ) : (
                        <span className="flex items-center gap-1 text-[10px] text-muted-foreground/40">
                          <Bell className="size-3" strokeWidth={1.5} />
                          Read
                        </span>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
              <Shield className="mb-3 size-10 opacity-20" strokeWidth={1} />
              <p className="text-sm font-medium">No alerts found</p>
              <p className="mt-1 text-xs opacity-60">Try adjusting your filters</p>
            </div>
          )}

          {/* Pagination */}
          {pagination && pagination.total_pages > 1 && (
            <div className="flex items-center justify-between border-t border-border px-5 py-3">
              <p className="text-xs text-muted-foreground">
                Showing {((pagination.page - 1) * pagination.per_page) + 1}–
                {Math.min(pagination.page * pagination.per_page, pagination.total)} of {pagination.total}
              </p>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => goToPage(pagination.page - 1)}
                  disabled={pagination.page === 1}
                  className="flex size-7 items-center justify-center rounded-md border border-border text-muted-foreground transition-colors hover:text-foreground disabled:cursor-not-allowed disabled:opacity-30"
                >
                  <ChevronLeft className="size-4" />
                </button>
                <span className="text-xs text-muted-foreground">
                  {pagination.page} / {pagination.total_pages}
                </span>
                <button
                  onClick={() => goToPage(pagination.page + 1)}
                  disabled={pagination.page === pagination.total_pages}
                  className="flex size-7 items-center justify-center rounded-md border border-border text-muted-foreground transition-colors hover:text-foreground disabled:cursor-not-allowed disabled:opacity-30"
                >
                  <ChevronRight className="size-4" />
                </button>
              </div>
            </div>
          )}
        </div>

      </div>
    </AppLayout>
  )
}

// ── FilterSelect sub-component ─────────────────────────────────────
function FilterSelect({
  label,
  value,
  onChange,
  options,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  options: { value: string; label: string }[]
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      aria-label={label}
      className="rounded-md border border-border bg-secondary px-3 py-1.5 text-xs font-medium text-foreground transition-colors hover:border-primary/40 focus:outline-none focus:ring-1 focus:ring-primary/40"
    >
      {options.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  )
}
