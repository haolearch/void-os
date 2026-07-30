import { AppShell } from "@/components/layout/app-shell";

export default function EmployeesPage() {
  return (
    <AppShell>
      <div className="rounded-[28px] border border-zinc-200 bg-white/80 p-6 shadow-[0_20px_60px_-30px_rgba(15,23,42,0.35)] backdrop-blur dark:border-zinc-800 dark:bg-zinc-900/80">
        <h1 className="text-2xl font-semibold text-zinc-950 dark:text-zinc-50">Employees</h1>
        <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-400">Teams, staffing, and internal operations.</p>
      </div>
    </AppShell>
  );
}
