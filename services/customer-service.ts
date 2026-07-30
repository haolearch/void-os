import { CustomerRepository } from "@/repositories/customer-repository";
import type { Customer } from "@/types";

export class CustomerService {
  constructor(private readonly repository = new CustomerRepository()) {}

  async getCustomers(): Promise<Customer[]> {
    return this.repository.getAll();
  }

  async getCustomer(id: number): Promise<Customer | null> {
    return this.repository.getById(id);
  }
}
