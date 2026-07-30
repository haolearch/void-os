"use client";

import {
  BriefcaseBusiness,
  FileText,
  FolderKanban,
  Handshake,
  Landmark,
  LayoutDashboard,
  Settings,
  Users,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { LucideIcon } from "lucide-react";

interface SidebarItem {
  label: string;
  icon: LucideIcon;
  href: string;
}

const items: SidebarItem[] = [
  { label: "Dashboard", icon: LayoutDashboard, href: "/dashboard" },
  { label: "Customers", icon: Users, href: "/customers" },
  { label: "Projects", icon: FolderKanban, href: "/projects" },
  { label: "Finance", icon: Landmark, href: "/finance" },
  { label: "Quotations", icon: FileText, href: "/quotations" },
  { label: "Contracts", icon: Handshake, href: "/contracts" },
  { label: "Employees", icon: BriefcaseBusiness, href: "/employees" },
  { label: "Settings", icon: Settings, href: "/settings" },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="border-b border-zinc-200/80 bg-white/80 p-4 backdrop-blur dark:border-zinc-800/80 dark:bg-zinc-950/80 lg:min-h-screen lg:w-72 lg:border-b-0 lg:border-r lg:p-6">
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-zinc-950 text-sm font-semibold text-white shadow-lg shadow-zinc-950/20 dark:bg-white dark:text-zinc-950">
          V
        </div>
        <div>
          <p className="text-sm font-semibold tracking-[0.24em] text-zinc-500 uppercase dark:text-zinc-400">
            VOID OS
          </p>
          <p className="text-sm text-zinc-600 dark:text-zinc-400">ERP command center</p>
        </div>
      </div>

      <nav className="mt-8 space-y-1">
        {items.map(({ label, icon: Icon, href }) => {
          const isActive = pathname === href || (href === "/dashboard" && pathname === "/");

          return (
            <Link
              key={label}
              href={href}
              className={`flex w-full items-center gap-3 rounded-2xl px-3 py-2.5 text-left text-sm font-medium transition ${
                isActive
                  ? "bg-zinc-950 text-white shadow-lg shadow-zinc-950/10 dark:bg-white dark:text-zinc-950"
                  : "text-zinc-600 hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-400 dark:hover:bg-zinc-900 dark:hover:text-white"
              }`}
            >
              <Icon className="h-4 w-4" />
              <span>{label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="mt-8 rounded-3xl border border-zinc-200 bg-zinc-50 p-4 dark:border-zinc-800 dark:bg-zinc-900/70">
        <p className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
          Next review
        </p>
        <p className="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
          Quarterly closing in 3 days.
        </p>
      </div>
    </aside>
  );
}
