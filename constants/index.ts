export const PROJECT_STATUS_LABELS = {
  Planning: "Planning",
  InProgress: "In Progress",
  OnHold: "On Hold",
  Completed: "Completed",
} as const;

export const CUSTOMER_STATUS_LABELS = {
  Active: "Active",
  Review: "Review",
  Pending: "Pending",
} as const;

export const PAYMENT_STATUS_LABELS = {
  Pending: "Pending",
  Paid: "Paid",
  Overdue: "Overdue",
} as const;

export const EXPENSE_CATEGORY_LABELS = {
  Payroll: "Payroll",
  Materials: "Materials",
  Travel: "Travel",
  Software: "Software",
  Other: "Other",
} as const;

export const PROJECT_TYPE_LABELS = {
  Residential: "Residential",
  Commercial: "Commercial",
  Interior: "Interior",
  Renovation: "Renovation",
} as const;
