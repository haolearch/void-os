"use client";

import { Bell, Moon, Search, Sun } from "lucide-react";
import { useEffect, useState } from "react";

export function TopNav() {
  const [isDark, setIsDark] = useState(true);

  useEffect(() => {
    const savedTheme = window.localStorage.getItem("void-theme");
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const initialDark = savedTheme ? savedTheme === "dark" : prefersDark;
    setIsDark(initialDark);
    document.documentElement.classList.toggle("dark", initialDark);
  }, []);

  const toggleTheme = () => {
    const next = !isDark;
    setIsDark(next);
    document.documentElement.classList.toggle("dark", next);
    window.localStorage.setItem("void-theme", next ? "dark" : "light");
  };

  return (
    <header className="sticky top-0 z-20 border-b border-zinc-200/80 bg-white/70 px-4 py-4 backdrop-blur dark:border-zinc-800/80 dark:bg-zinc-950/70 sm:px-6 lg:px-8">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3 rounded-2xl border border-zinc-200 bg-zinc-50 px-3 py-2 text-sm text-zinc-500 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-400">
          <Search className="h-4 w-4" />
          <span>Search insights, clients, invoices</span>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={toggleTheme}
            className="rounded-2xl border border-zinc-200 bg-white p-2.5 text-zinc-600 transition hover:border-zinc-300 hover:text-zinc-950 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-300 dark:hover:border-zinc-700 dark:hover:text-white"
            aria-label="Toggle color theme"
          >
            {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </button>
          <button className="rounded-2xl border border-zinc-200 bg-white p-2.5 text-zinc-600 transition hover:border-zinc-300 hover:text-zinc-950 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-300 dark:hover:border-zinc-700 dark:hover:text-white">
            <Bell className="h-4 w-4" />
          </button>
          <div className="flex items-center gap-3 rounded-2xl border border-zinc-200 bg-white px-3 py-2 dark:border-zinc-800 dark:bg-zinc-900">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-fuchsia-500 to-violet-600 font-semibold text-white">
              MK
            </div>
            <div className="hidden sm:block">
              <p className="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Maya Kim</p>
              <p className="text-xs text-zinc-500 dark:text-zinc-400">Operations Lead</p>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
