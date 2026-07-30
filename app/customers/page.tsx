import { AppShell } from "@/components/layout/app-shell";
import { CustomerTable } from "@/components/customers/customer-table";
import { CustomerStatus, type Customer } from "@/types";

const customers: Customer[] = [
  {
    id: 1,
    company: "Aurelia Residence",
    contact: "Nina Patel",
    phone: "+1 (212) 555-0148",
    email: "nina@aureliaresidence.com",
    projects: 3,
    revenue: "$184K",
    status: CustomerStatus.Active,
  },
  {
    id: 2,
    company: "Northwind Studio",
    contact: "Marcus Chen",
    phone: "+1 (415) 555-0182",
    email: "marcus@northwindstudio.com",
    projects: 2,
    revenue: "$126K",
    status: CustomerStatus.Review,
  },
  {
    id: 3,
    company: "Harbor & Oak",
    contact: "Elena Brooks",
    phone: "+1 (310) 555-0119",
    email: "elena@harborandoak.com",
    projects: 4,
    revenue: "$241K",
    status: CustomerStatus.Active,
  },
  {
    id: 4,
    company: "Cedar House Co.",
    contact: "Daniel Ruiz",
    phone: "+1 (604) 555-0174",
    email: "daniel@cedarhouse.co",
    projects: 1,
    revenue: "$58K",
    status: CustomerStatus.Pending,
  },
  {
    id: 5,
    company: "Marlowe Interiors",
    contact: "Sofia Alvarez",
    phone: "+1 (312) 555-0136",
    email: "sofia@marloweinteriors.com",
    projects: 5,
    revenue: "$312K",
    status: CustomerStatus.Active,
  },
  {
    id: 6,
    company: "Lumen Atelier",
    contact: "James Walker",
    phone: "+1 (646) 555-0124",
    email: "james@lumenatelier.com",
    projects: 2,
    revenue: "$97K",
    status: CustomerStatus.Review,
  },
  {
    id: 7,
    company: "Solstice Collective",
    contact: "Priya Singh",
    phone: "+1 (206) 555-0157",
    email: "priya@solsticecollective.com",
    projects: 3,
    revenue: "$171K",
    status: CustomerStatus.Active,
  },
  {
    id: 8,
    company: "Briar & Stone",
    contact: "Caleb Foster",
    phone: "+1 (305) 555-0188",
    email: "caleb@briarandstone.com",
    projects: 2,
    revenue: "$89K",
    status: CustomerStatus.Pending,
  },
  {
    id: 9,
    company: "Atelier Vale",
    contact: "Maya Torres",
    phone: "+1 (720) 555-0163",
    email: "maya@ateliervale.com",
    projects: 4,
    revenue: "$228K",
    status: CustomerStatus.Active,
  },
  {
    id: 10,
    company: "Verdant House",
    contact: "Liam Carter",
    phone: "+1 (917) 555-0141",
    email: "liam@verdanthouse.com",
    projects: 1,
    revenue: "$63K",
    status: CustomerStatus.Review,
  },
];

export default function CustomersPage() {
  return (
    <AppShell>
      <div className="space-y-6">
        <div className="flex flex-col gap-2">
          <h1 className="text-3xl font-semibold tracking-tight text-zinc-950 dark:text-zinc-50">Customers</h1>
          <p className="text-sm text-zinc-600 dark:text-zinc-400">Manage all clients of VOID Design & Build</p>
        </div>

        <CustomerTable customers={customers} />
      </div>
    </AppShell>
  );
}
