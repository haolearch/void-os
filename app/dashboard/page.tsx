import { AppShell } from "@/components/layout/app-shell";
import { MetricCard } from "@/components/dashboard/metric-card";
import { WelcomeCard } from "@/components/dashboard/welcome-card";
import { ArrowRightLeft, BadgeDollarSign, BarChart3, CircleDollarSign, Landmark, TrendingUp } from "lucide-react";

const metrics = [
  {
    title: "Revenue",
    value: "$284.2K",
    detail: "+12.8% vs last month",
    icon: CircleDollarSign,
    tone: "violet" as const,
  },
  {
    title: "Expenses",
    value: "$134.9K",
    detail: "Within budget target",
    icon: BadgeDollarSign,
    tone: "amber" as const,
  },
  {
    title: "Profit",
    value: "$149.3K",
    detail: "Healthy margin trend",
    icon: TrendingUp,
    tone: "emerald" as const,
  },
  {
    title: "Cash Flow",
    value: "$42.1K",
    detail: "Positive runway forecast",
    icon: ArrowRightLeft,
    tone: "sky" as const,
  },
];

export default function DashboardPage() {
  return (
    <AppShell>
      <div className="space-y-6">
        <WelcomeCard />

        <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {metrics.map((item) => (
            <MetricCard key={item.title} {...item} />
          ))}
        </section>

        <section className="grid gap-6 xl:grid-cols-[1.5fr_0.9fr]">
          <div className="rounded-[28px] border border-zinc-200 bg-white/80 p-6 shadow-[0_20px_60px_-30px_rgba(15,23,42,0.35)] backdrop-blur dark:border-zinc-800 dark:bg-zinc-900/80">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-zinc-500 dark:text-zinc-400">Operations snapshot</p>
                <h2 className="mt-1 text-xl font-semibold text-zinc-950 dark:text-zinc-50">
                  Delivery health this quarter
                </h2>
              </div>
              <div className="rounded-2xl bg-zinc-100 p-2 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">
                <BarChart3 className="h-5 w-5" />
              </div>
            </div>

            <div className="mt-6 grid gap-4 sm:grid-cols-3">
              {[
                { label: "On track", value: "87%" },
                { label: "At risk", value: "6%" },
                { label: "Delayed", value: "7%" },
              ].map((stat) => (
                <div key={stat.label} className="rounded-2xl bg-zinc-50 p-4 dark:bg-zinc-800/70">
                  <p className="text-sm text-zinc-500 dark:text-zinc-400">{stat.label}</p>
                  <p className="mt-2 text-2xl font-semibold text-zinc-950 dark:text-zinc-50">{stat.value}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-[28px] border border-zinc-200 bg-white/80 p-6 shadow-[0_20px_60px_-30px_rgba(15,23,42,0.35)] backdrop-blur dark:border-zinc-800 dark:bg-zinc-900/80">
            <div className="flex items-center gap-3">
              <div className="rounded-2xl bg-violet-100 p-2 text-violet-700 dark:bg-violet-500/10 dark:text-violet-300">
                <Landmark className="h-5 w-5" />
              </div>
              <div>
                <p className="text-sm text-zinc-500 dark:text-zinc-400">Financial pulse</p>
                <h2 className="text-xl font-semibold text-zinc-950 dark:text-zinc-50">Cash runway</h2>
              </div>
            </div>

            <div className="mt-6 space-y-4">
              {[
                ["Available cash", "$118K"],
                ["Accounts receivable", "$56K"],
                ["Upcoming payouts", "$24K"],
              ].map(([label, value]) => (
                <div key={label} className="flex items-center justify-between rounded-2xl bg-zinc-50 px-4 py-3 dark:bg-zinc-800/70">
                  <span className="text-sm text-zinc-600 dark:text-zinc-400">{label}</span>
                  <span className="font-semibold text-zinc-950 dark:text-zinc-50">{value}</span>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
