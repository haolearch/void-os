import { MoreHorizontal, Search, SlidersHorizontal } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import type { Customer } from "@/types";

interface CustomerTableProps {
  customers: Customer[];
}

export function CustomerTable({ customers }: CustomerTableProps) {
  return (
    <div className="overflow-hidden rounded-[28px] border border-zinc-200 bg-white/80 shadow-[0_20px_60px_-30px_rgba(15,23,42,0.35)] backdrop-blur dark:border-zinc-800 dark:bg-zinc-900/80">
      <div className="flex flex-col gap-3 border-b border-zinc-200 p-4 sm:flex-row sm:items-center sm:justify-between dark:border-zinc-800">
        <div>
          <h2 className="text-lg font-semibold text-zinc-950 dark:text-zinc-50">Customer directory</h2>
          <p className="text-sm text-zinc-600 dark:text-zinc-400">Tracked across all active engagements.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <label className="flex items-center gap-2 rounded-2xl border border-zinc-200 bg-zinc-50 px-3 py-2 text-sm text-zinc-500 dark:border-zinc-800 dark:bg-zinc-800/70 dark:text-zinc-400">
            <Search className="h-4 w-4" />
            <input
              className="w-36 bg-transparent outline-none sm:w-48"
              placeholder="Search"
              aria-label="Search customers"
            />
          </label>
          <button className="flex items-center gap-2 rounded-2xl border border-zinc-200 bg-white px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-200 dark:hover:bg-zinc-800">
            <SlidersHorizontal className="h-4 w-4" />
            Filter
          </button>
          <button className="rounded-2xl bg-zinc-950 px-3 py-2 text-sm font-medium text-white transition hover:bg-zinc-800 dark:bg-white dark:text-zinc-950 dark:hover:bg-zinc-100">
            Add Customer
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-zinc-50 text-zinc-600 dark:bg-zinc-800/70 dark:text-zinc-300">
            <tr>
              <th className="px-4 py-3 font-medium">Company</th>
              <th className="px-4 py-3 font-medium">Contact</th>
              <th className="px-4 py-3 font-medium">Phone</th>
              <th className="px-4 py-3 font-medium">Email</th>
              <th className="px-4 py-3 font-medium">Total Projects</th>
              <th className="px-4 py-3 font-medium">Total Revenue</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody>
            {customers.map((customer) => (
              <tr key={customer.id} className="border-t border-zinc-200 text-zinc-700 dark:border-zinc-800 dark:text-zinc-300">
                <td className="px-4 py-3 font-semibold text-zinc-950 dark:text-zinc-50">{customer.company}</td>
                <td className="px-4 py-3">{customer.contact}</td>
                <td className="px-4 py-3">{customer.phone}</td>
                <td className="px-4 py-3">{customer.email}</td>
                <td className="px-4 py-3">{customer.projects}</td>
                <td className="px-4 py-3">{customer.revenue}</td>
                <td className="px-4 py-3">
                  <Badge status={customer.status} />
                </td>
                <td className="px-4 py-3">
                  <button className="rounded-2xl border border-zinc-200 p-2 text-zinc-600 transition hover:bg-zinc-100 dark:border-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-800">
                    <MoreHorizontal className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
