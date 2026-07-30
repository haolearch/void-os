import type { Customer } from "@/types";

export class CustomerRepository {
  async getAll(): Promise<Customer[]> {
    return [];
  }

  async getById(id: number): Promise<Customer | null> {
    return null;
  }
}
