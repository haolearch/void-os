import { ArrowUpRight, Sparkles } from "lucide-react";

export function WelcomeCard() {
  return (
    <div className="rounded-[32px] border border-zinc-200 bg-zinc-950 p-6 text-white shadow-[0_24px_80px_-30px_rgba(17,24,39,0.9)] dark:border-zinc-800 dark:bg-zinc-900">
      <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
        <div className="max-w-2xl">
          <div className="flex items-center gap-2 text-sm font-medium text-violet-300">
            <Sparkles className="h-4 w-4" />
            Your workspace is thriving
          </div>
          <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">
            Welcome back, Maya. Your ERP is running smoothly.
          </h1>
          <p className="mt-3 max-w-xl text-sm leading-7 text-zinc-300 sm:text-base">
            Review this week’s performance, monitor cash health, and keep every customer and project moving in sync.
          </p>
        </div>

        <button className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-4 py-3 text-sm font-semibold text-zinc-950 transition hover:bg-zinc-100">
          Open reports
          <ArrowUpRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
