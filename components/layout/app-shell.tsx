import { Sidebar } from "@/components/layout/sidebar";
import { TopNav } from "@/components/layout/top-nav";

export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,_rgba(168,85,247,0.14),_transparent_35%),linear-gradient(180deg,_#f8fafc_0%,_#f5f7fb_100%)] text-zinc-900 transition-colors dark:bg-[radial-gradient(circle_at_top_left,_rgba(192,132,252,0.16),_transparent_35%),linear-gradient(180deg,_#020617_0%,_#09090b_100%)] dark:text-zinc-50">
      <div className="mx-auto flex max-w-7xl flex-col lg:flex-row">
        <Sidebar />
        <div className="flex-1">
          <TopNav />
          <main className="p-4 sm:p-6 lg:p-8">{children}</main>
        </div>
      </div>
    </div>
  );
}
