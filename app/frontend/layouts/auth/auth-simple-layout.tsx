import { Link } from "@inertiajs/react"
import type { PropsWithChildren } from "react"

import { rootPath } from "@/routes"

interface AuthLayoutProps {
  name?: string
  title?: string
  description?: string
}

export default function AuthSimpleLayout({
  children,
  title,
  description,
}: PropsWithChildren<AuthLayoutProps>) {
  return (
    <div className="relative grid min-h-svh lg:grid-cols-2">

      {/* ── Left panel — branding ─────────────────────────── */}
      <div className="relative hidden flex-col overflow-hidden lg:flex" style={{ background: "oklch(0.11 0.02 250)" }}>

        {/* Subtle grid */}
        <div
          className="absolute inset-0"
          style={{
            backgroundImage: `
              linear-gradient(oklch(0.93 0.01 250 / 0.03) 1px, transparent 1px),
              linear-gradient(90deg, oklch(0.93 0.01 250 / 0.03) 1px, transparent 1px)
            `,
            backgroundSize: "48px 48px",
          }}
        />

        {/* Coral glow blob top-right */}
        <div
          className="absolute -top-32 -right-32 h-96 w-96 rounded-full opacity-20"
          style={{
            background: "radial-gradient(circle, oklch(0.62 0.22 28) 0%, transparent 70%)",
          }}
        />

        {/* Teal glow blob bottom-left */}
        <div
          className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full opacity-15"
          style={{
            background: "radial-gradient(circle, oklch(0.65 0.14 195) 0%, transparent 70%)",
          }}
        />

        {/* Content */}
        <div className="relative z-10 flex h-full flex-col p-12">

          {/* Logo */}
          <Link href={rootPath()} className="flex items-center gap-3">
            <div
              className="flex size-9 items-center justify-center rounded-lg"
              style={{
                background: "oklch(0.62 0.22 28)",
                boxShadow: "0 0 16px oklch(0.62 0.22 28 / 0.5)",
              }}
            >
              {/* Shield icon inline so we don't need an import */}
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
              </svg>
            </div>
            <div className="flex flex-col">
              <span className="font-display text-lg font-semibold leading-none text-white">
                Luminox
              </span>
              <span
                className="text-[10px] font-semibold uppercase tracking-widest"
                style={{ color: "oklch(0.55 0.02 250)" }}
              >
                Security Platform
              </span>
            </div>
          </Link>

          {/* Center stats */}
          <div className="flex flex-1 flex-col justify-center gap-10">
            <div>
              <p
                className="mb-3 text-xs font-semibold uppercase tracking-widest"
                style={{ color: "oklch(0.55 0.02 250)" }}
              >
                Platform Status
              </p>
              <div className="flex items-center gap-2">
                <span
                  className="inline-block h-2 w-2 rounded-full"
                  style={{
                    background: "oklch(0.79 0.19 160)",
                    boxShadow: "0 0 8px oklch(0.79 0.19 160)",
                    animation: "lx-pulse 2s ease-in-out infinite",
                  }}
                />
                <span className="font-body text-sm font-medium text-white">
                  All systems operational
                </span>
              </div>
            </div>

            {/* Stat pills */}
            <div className="grid grid-cols-2 gap-4">
              {[
                { label: "Threats Blocked", value: "1.2M+", color: "oklch(0.62 0.22 28)" },
                { label: "Uptime", value: "99.9%", color: "oklch(0.65 0.14 195)" },
                { label: "Response Time", value: "< 5min", color: "oklch(0.72 0.15 145)" },
                { label: "Nodes Monitored", value: "2,841", color: "oklch(0.75 0.12 60)" },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="rounded-xl p-4"
                  style={{
                    background: "oklch(0.16 0.02 250)",
                    border: "1px solid oklch(0.24 0.025 250)",
                  }}
                >
                  <p
                    className="font-display text-2xl font-bold"
                    style={{ color: stat.color }}
                  >
                    {stat.value}
                  </p>
                  <p
                    className="mt-1 text-xs font-medium"
                    style={{ color: "oklch(0.55 0.02 250)" }}
                  >
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>
          </div>

          {/* Footer quote */}
          <div
            className="rounded-xl p-5"
            style={{
              background: "oklch(0.16 0.02 250)",
              border: "1px solid oklch(0.24 0.025 250)",
            }}
          >
            <p className="font-body text-sm leading-relaxed" style={{ color: "oklch(0.70 0.01 250)" }}>
              &ldquo;Real-time threat intelligence that keeps your infrastructure one step ahead of adversaries.&rdquo;
            </p>
            <p className="mt-2 text-xs font-semibold uppercase tracking-widest" style={{ color: "oklch(0.45 0.02 250)" }}>
              Luminox Security
            </p>
          </div>
        </div>
      </div>

      {/* ── Right panel — form ────────────────────────────── */}
      <div
        className="flex flex-col items-center justify-center p-8"
        style={{ background: "oklch(0.13 0.02 250)" }}
      >
        {/* Mobile logo */}
        <Link href={rootPath()} className="mb-10 flex items-center gap-3 lg:hidden">
          <div
            className="flex size-9 items-center justify-center rounded-lg"
            style={{
              background: "oklch(0.62 0.22 28)",
              boxShadow: "0 0 16px oklch(0.62 0.22 28 / 0.5)",
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
            </svg>
          </div>
          <span className="font-display text-lg font-semibold text-white">Luminox</span>
        </Link>

        <div className="w-full max-w-sm">
          {/* Heading */}
          <div className="mb-8 space-y-2">
            <h1 className="font-display text-2xl font-semibold text-white">
              {title}
            </h1>
            <p className="font-body text-sm" style={{ color: "oklch(0.55 0.02 250)" }}>
              {description}
            </p>
          </div>

          {/* Form slot */}
          {children}
        </div>
      </div>

    </div>
  )
}
