import { Link, usePage } from "@inertiajs/react"

import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import type { NavItem } from "@/types"

export function NavMain({
  items = [],
  groupLabel,
}: {
  items: NavItem[]
  groupLabel?: string
}) {
  const page = usePage()
  return (
    <SidebarGroup className="px-2 py-0">
      {groupLabel && (
        <SidebarGroupLabel className="mb-1 text-[10px] font-semibold uppercase tracking-widest text-muted-foreground/60">
          {groupLabel}
        </SidebarGroupLabel>
      )}
      <SidebarMenu>
        {items.map((item) => {
          const isActive = page.url === item.href || page.url.startsWith(item.href + "/")
          return (
            <SidebarMenuItem key={item.title}>
              <SidebarMenuButton
                asChild
                isActive={isActive}
                tooltip={{ children: item.title }}
                className={
                  isActive
                    ? "relative border-l-2 border-primary bg-gradient-to-r from-primary/15 to-transparent text-foreground"
                    : "text-muted-foreground hover:text-foreground"
                }
              >
                <Link href={item.href} prefetch>
                  {item.icon && (
                    <item.icon
                      className={isActive ? "text-primary" : "text-muted-foreground"}
                      strokeWidth={isActive ? 2 : 1.5}
                    />
                  )}
                  <span className="font-medium">{item.title}</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          )
        })}
      </SidebarMenu>
    </SidebarGroup>
  )
}
