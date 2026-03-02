import { Link } from "@inertiajs/react"
import {
  Activity,
  AlertTriangle,
  Bell,
  Globe,
  Layers,
  LayoutGrid,
  Lock,
  Radio,
  Search,
  Settings,
  Shield,
  Users,
} from "lucide-react"

import { NavMain } from "@/components/nav-main"
import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar"
import { dashboardPath } from "@/routes"
import type { NavItem } from "@/types"

const mainNavItems: NavItem[] = [
  {
    title: "Overview",
    href: dashboardPath(),
    icon: LayoutGrid,
  },
  {
    title: "Threat Monitor",
    href: "/threats",
    icon: AlertTriangle,
  },
  {
    title: "Live Feed",
    href: "/feed",
    icon: Radio,
  },
  {
    title: "Network Map",
    href: "/network",
    icon: Globe,
  },
  {
    title: "Incidents",
    href: "/incidents",
    icon: Shield,
  },
  {
    title: "Alerts",
    href: "/alerts",
    icon: Bell,
  },
]

const analysisNavItems: NavItem[] = [
  {
    title: "Intelligence",
    href: "/intelligence",
    icon: Layers,
  },
  {
    title: "Activity Log",
    href: "/activity",
    icon: Activity,
  },
  {
    title: "Search",
    href: "/search",
    icon: Search,
  },
]

const adminNavItems: NavItem[] = [
  {
    title: "Users",
    href: "/settings/users",
    icon: Users,
  },
  {
    title: "Access Control",
    href: "/settings/access",
    icon: Lock,
  },
  {
    title: "Settings",
    href: "/settings/profiles/show",
    icon: Settings,
  },
]

export function AppSidebar() {
  return (
    <Sidebar collapsible="icon" variant="inset">
      {/* ── Logo / Brand ─────────────────────────────────── */}
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" asChild>
              <Link href={dashboardPath()} prefetch>
                <div className="flex aspect-square size-8 items-center justify-center rounded-lg bg-primary shadow-[0_0_12px_oklch(0.62_0.22_28/0.6)]">
                  <Shield className="size-4 text-primary-foreground" strokeWidth={2.5} />
                </div>
                <div className="flex flex-col gap-0.5 leading-none">
                  <span className="font-display text-base font-semibold tracking-tight text-foreground">
                    Luminox
                  </span>
                  <span className="text-[10px] font-medium uppercase tracking-widest text-muted-foreground">
                    Security Platform
                  </span>
                </div>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      {/* ── Nav Content ──────────────────────────────────── */}
      <SidebarContent>
        {/* Monitoring */}
        <NavMain items={mainNavItems} groupLabel="Monitoring" />

        <SidebarSeparator className="mx-3 opacity-30" />

        {/* Analysis */}
        <NavMain items={analysisNavItems} groupLabel="Analysis" />

        <SidebarSeparator className="mx-3 opacity-30" />

        {/* Admin */}
        <NavMain items={adminNavItems} groupLabel="Admin" />
      </SidebarContent>

      {/* ── Footer ───────────────────────────────────────── */}
      <SidebarFooter>
        {/* System status pill */}
        <div className="mx-2 mb-2 flex items-center gap-2 rounded-lg border border-border/50 bg-sidebar-accent/50 px-3 py-2">
          <span className="lx-dot-active" />
          <span className="text-xs font-medium text-muted-foreground">All systems nominal</span>
        </div>
        <NavUser />
      </SidebarFooter>
    </Sidebar>
  )
}
