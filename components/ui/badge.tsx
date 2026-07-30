import { CustomerStatus } from "@/types";

interface BadgeProps {
  status: CustomerStatus;
}

export function Badge({ status }: BadgeProps) {
  const styles = {
    [CustomerStatus.Active]: "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300",
    [CustomerStatus.Review]: "bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300",
    [CustomerStatus.Pending]: "bg-sky-100 text-sky-700 dark:bg-sky-500/10 dark:text-sky-300",
  } as const;

  return (
    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${styles[status]}`}>
      {status}
    </span>
  );
}
