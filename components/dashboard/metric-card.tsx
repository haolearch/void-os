import type { LucideIcon } from "lucide-react";

interface MetricCardProps {
  title: string;
  value: string;
  detail: string;
  icon: LucideIcon;
  tone: "violet" | "emerald" | "sky" | "amber";
}

const toneStyles = {
  violet: "from-violet-500/15 to-fuchsia-500/10 text-violet-600 dark:text-violet-300",
  emerald: "from-emerald-500/15 to-teal-500/10 text-emerald-600 dark:text-emerald-300",
  sky: "from-sky-500/15 to-cyan-500/10 text-sky-600 dark:text-sky-300",
  amber: "from-amber-500/15 to-orange-500/10 text-amber-600 dark:text-amber-300",
};

export function MetricCard({ title, value, detail, icon: Icon, tone }: MetricCardProps) {
  return (
    <div className="rounded-3xl border border-zinc-200 bg-white/80 p-5 shadow-[0_12px_40px_-24px_rgba(15,23,42,0.35)] backdrop-blur dark:border-zinc-800 dark:bg-zinc-900/80">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-sm text-zinc-500 dark:text-zinc-400">{title}</p>
          <p className="mt-2 text-2xl font-semibold text-zinc-950 dark:text-zinc-50">{value}</p>
        </div>
        <div className={`rounded-2xl bg-gradient-to-br p-2.5 ${toneStyles[tone]}`}>
          <Icon className="h-5 w-5" />
        </div>
      </div>
      <p className="mt-4 text-sm text-zinc-600 dark:text-zinc-400">{detail}</p>
    </div>
  );
}
