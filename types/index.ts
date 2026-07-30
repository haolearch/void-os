export enum ProjectStatus {
  Planning = "Planning",
  InProgress = "In Progress",
  OnHold = "On Hold",
  Completed = "Completed",
}

export enum CustomerStatus {
  Active = "Active",
  Review = "Review",
  Pending = "Pending",
}

export enum PaymentStatus {
  Pending = "Pending",
  Paid = "Paid",
  Overdue = "Overdue",
}

export enum ExpenseCategory {
  Payroll = "Payroll",
  Materials = "Materials",
  Travel = "Travel",
  Software = "Software",
  Other = "Other",
}

export enum ProjectType {
  Residential = "Residential",
  Commercial = "Commercial",
  Interior = "Interior",
  Renovation = "Renovation",
}

export interface Customer {
  id: number;
  company: string;
  contact: string;
  phone: string;
  email: string;
  projects: number;
  revenue: string;
  status: CustomerStatus;
}

export interface Project {
  id: number;
  name: string;
  customerId: number;
  type: ProjectType;
  status: ProjectStatus;
  budget: number;
  deadline: string;
}

export interface Quotation {
  id: number;
  projectId: number;
  clientName: string;
  total: number;
  validUntil: string;
  status: string;
}

export interface Contract {
  id: number;
  projectId: number;
  clientName: string;
  value: number;
  signedOn: string;
  status: string;
}

export interface Payment {
  id: number;
  contractId: number;
  amount: number;
  status: PaymentStatus;
  dueDate: string;
}

export interface Expense {
  id: number;
  projectId: number;
  category: ExpenseCategory;
  amount: number;
  incurredOn: string;
  notes: string;
}

export interface Employee {
  id: number;
  name: string;
  role: string;
  email: string;
  phone: string;
  department: string;
}
