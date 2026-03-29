import "server-only";

import type { PoolClient } from "pg";
import { getPool } from "@/lib/database/client";
import type {
  CloverCategory,
  CloverCustomer,
  CloverDiscount,
  CloverEmployee,
  CloverItem,
  CloverOrder,
  CloverPayment,
  CloverStock,
  CloverSyncSnapshot,
} from "@/lib/clover/types";

interface CloverSyncResult {
  merchantId: string;
  counts: {
    customers: number;
    employees: number;
    categories: number;
    discounts: number;
    items: number;
    stocks: number;
    orders: number;
    lineItems: number;
    payments: number;
  };
}

function toJsonb(value: unknown): string {
  return JSON.stringify(value ?? null);
}

async function withTransaction<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const pool = getPool();
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function upsertMerchant(client: PoolClient, snapshot: CloverSyncSnapshot): Promise<string> {
  const merchant = snapshot.merchant;

  const sql = `
    INSERT INTO public.clover_merchants (
      clover_merchant_id,
      merchant_name,
      country,
      currency,
      timezone,
      raw_payload,
      last_synced_at,
      updated_at
    )
    VALUES ($1, $2, $3, $4, $5, $6::jsonb, now(), now())
    ON CONFLICT (clover_merchant_id)
    DO UPDATE SET
      merchant_name = EXCLUDED.merchant_name,
      country = EXCLUDED.country,
      currency = EXCLUDED.currency,
      timezone = EXCLUDED.timezone,
      raw_payload = EXCLUDED.raw_payload,
      last_synced_at = EXCLUDED.last_synced_at,
      updated_at = now()
    RETURNING id
  `;

  const result = await client.query<{ id: string }>(sql, [
    merchant.id,
    merchant.name ?? null,
    merchant.country ?? null,
    merchant.currency ?? null,
    merchant.timezone ?? null,
    toJsonb(merchant),
  ]);

  return result.rows[0].id;
}

async function upsertCustomers(
  client: PoolClient,
  merchantId: string,
  customers: CloverCustomer[],
): Promise<Map<string, string>> {
  const map = new Map<string, string>();

  for (const customer of customers) {
    const customerSql = `
      INSERT INTO public.clover_customers (
        merchant_id,
        clover_customer_id,
        first_name,
        last_name,
        marketing_allowed,
        clover_created_time,
        clover_modified_time,
        raw_payload,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, now())
      ON CONFLICT (merchant_id, clover_customer_id)
      DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        marketing_allowed = EXCLUDED.marketing_allowed,
        clover_created_time = EXCLUDED.clover_created_time,
        clover_modified_time = EXCLUDED.clover_modified_time,
        raw_payload = EXCLUDED.raw_payload,
        updated_at = now()
      RETURNING id
    `;

    const result = await client.query<{ id: string }>(customerSql, [
      merchantId,
      customer.id,
      customer.firstName ?? null,
      customer.lastName ?? null,
      customer.marketingAllowed ?? null,
      customer.createdTime ?? null,
      customer.modifiedTime ?? null,
      toJsonb(customer),
    ]);

    const customerDbId = result.rows[0].id;
    map.set(customer.id, customerDbId);

    if (customer.emailAddresses?.elements?.length) {
      for (const email of customer.emailAddresses.elements) {
        await client.query(
          `
            INSERT INTO public.clover_customer_emails (
              customer_id,
              clover_email_id,
              email_address,
              raw_payload
            )
            VALUES ($1, $2, $3, $4::jsonb)
            ON CONFLICT (customer_id, email_address)
            DO UPDATE SET
              clover_email_id = EXCLUDED.clover_email_id,
              raw_payload = EXCLUDED.raw_payload
          `,
          [customerDbId, email.id, email.emailAddress, toJsonb(email)],
        );
      }
    }

    if (customer.phoneNumbers?.elements?.length) {
      for (const phone of customer.phoneNumbers.elements) {
        await client.query(
          `
            INSERT INTO public.clover_customer_phones (
              customer_id,
              clover_phone_id,
              phone_number,
              raw_payload
            )
            VALUES ($1, $2, $3, $4::jsonb)
            ON CONFLICT (customer_id, phone_number)
            DO UPDATE SET
              clover_phone_id = EXCLUDED.clover_phone_id,
              raw_payload = EXCLUDED.raw_payload
          `,
          [customerDbId, phone.id, phone.phoneNumber, toJsonb(phone)],
        );
      }
    }

    if (customer.addresses?.elements?.length) {
      for (const address of customer.addresses.elements) {
        await client.query(
          `
            INSERT INTO public.clover_customer_addresses (
              customer_id,
              clover_address_id,
              address1,
              city,
              state,
              zip,
              raw_payload
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb)
          `,
          [
            customerDbId,
            address.id,
            address.address1 ?? null,
            address.city ?? null,
            address.state ?? null,
            address.zip ?? null,
            toJsonb(address),
          ],
        );
      }
    }
  }

  return map;
}

async function upsertEmployees(
  client: PoolClient,
  merchantId: string,
  employees: CloverEmployee[],
): Promise<Map<string, string>> {
  const map = new Map<string, string>();

  for (const employee of employees) {
    const result = await client.query<{ id: string }>(
      `
        INSERT INTO public.clover_employees (
          merchant_id,
          clover_employee_id,
          name,
          role,
          clover_created_time,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, now())
        ON CONFLICT (merchant_id, clover_employee_id)
        DO UPDATE SET
          name = EXCLUDED.name,
          role = EXCLUDED.role,
          clover_created_time = EXCLUDED.clover_created_time,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
        RETURNING id
      `,
      [
        merchantId,
        employee.id,
        employee.name ?? null,
        employee.role ?? null,
        employee.createdTime ?? null,
        employee.modifiedTime ?? null,
        toJsonb(employee),
      ],
    );

    map.set(employee.id, result.rows[0].id);
  }

  return map;
}

async function upsertCategories(
  client: PoolClient,
  merchantId: string,
  categories: CloverCategory[],
): Promise<Map<string, string>> {
  const map = new Map<string, string>();

  for (const category of categories) {
    const result = await client.query<{ id: string }>(
      `
        INSERT INTO public.clover_categories (
          merchant_id,
          clover_category_id,
          name,
          sort_order,
          clover_created_time,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, now())
        ON CONFLICT (merchant_id, clover_category_id)
        DO UPDATE SET
          name = EXCLUDED.name,
          sort_order = EXCLUDED.sort_order,
          clover_created_time = EXCLUDED.clover_created_time,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
        RETURNING id
      `,
      [
        merchantId,
        category.id,
        category.name,
        category.sortOrder ?? null,
        category.createdTime ?? null,
        category.modifiedTime ?? null,
        toJsonb(category),
      ],
    );

    map.set(category.id, result.rows[0].id);
  }

  return map;
}

async function upsertDiscounts(
  client: PoolClient,
  merchantId: string,
  discounts: CloverDiscount[],
): Promise<void> {
  for (const discount of discounts) {
    await client.query(
      `
        INSERT INTO public.clover_discounts (
          merchant_id,
          clover_discount_id,
          name,
          amount,
          percentage,
          clover_created_time,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, now())
        ON CONFLICT (merchant_id, clover_discount_id)
        DO UPDATE SET
          name = EXCLUDED.name,
          amount = EXCLUDED.amount,
          percentage = EXCLUDED.percentage,
          clover_created_time = EXCLUDED.clover_created_time,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
      `,
      [
        merchantId,
        discount.id,
        discount.name,
        discount.amount ?? null,
        discount.percentage ?? null,
        discount.createdTime ?? null,
        discount.modifiedTime ?? null,
        toJsonb(discount),
      ],
    );
  }
}

async function upsertItems(
  client: PoolClient,
  merchantId: string,
  items: CloverItem[],
  categoryMap: Map<string, string>,
): Promise<Map<string, string>> {
  const itemMap = new Map<string, string>();

  for (const item of items) {
    const itemResult = await client.query<{ id: string }>(
      `
        INSERT INTO public.clover_items (
          merchant_id,
          clover_item_id,
          code,
          name,
          description,
          price,
          hidden,
          stock_count,
          quantity,
          clover_created_time,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb, now())
        ON CONFLICT (merchant_id, clover_item_id)
        DO UPDATE SET
          code = EXCLUDED.code,
          name = EXCLUDED.name,
          description = EXCLUDED.description,
          price = EXCLUDED.price,
          hidden = EXCLUDED.hidden,
          stock_count = EXCLUDED.stock_count,
          quantity = EXCLUDED.quantity,
          clover_created_time = EXCLUDED.clover_created_time,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
        RETURNING id
      `,
      [
        merchantId,
        item.id,
        item.code ?? null,
        item.name,
        item.description ?? null,
        item.price,
        item.hidden ?? null,
        item.stockCount ?? null,
        item.quantity ?? null,
        item.createdTime ?? null,
        item.modifiedTime ?? null,
        toJsonb(item),
      ],
    );

    const itemDbId = itemResult.rows[0].id;
    itemMap.set(item.id, itemDbId);

    if (item.categories?.elements?.length) {
      for (const category of item.categories.elements) {
        const categoryDbId = categoryMap.get(category.id);
        if (!categoryDbId) {
          continue;
        }

        await client.query(
          `
            INSERT INTO public.clover_item_categories (item_id, category_id)
            VALUES ($1, $2)
            ON CONFLICT (item_id, category_id)
            DO NOTHING
          `,
          [itemDbId, categoryDbId],
        );
      }
    }
  }

  return itemMap;
}

async function upsertStocks(
  client: PoolClient,
  stocks: CloverStock[],
  itemMap: Map<string, string>,
): Promise<void> {
  for (const stock of stocks) {
    const itemDbId = itemMap.get(stock.item.id);
    if (!itemDbId) {
      continue;
    }

    await client.query(
      `
        INSERT INTO public.clover_stocks (
          item_id,
          quantity,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4::jsonb, now())
        ON CONFLICT (item_id)
        DO UPDATE SET
          quantity = EXCLUDED.quantity,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
      `,
      [itemDbId, stock.quantity, stock.modifiedTime ?? null, toJsonb(stock)],
    );
  }
}

async function upsertOrders(
  client: PoolClient,
  merchantId: string,
  orders: CloverOrder[],
  customerMap: Map<string, string>,
  employeeMap: Map<string, string>,
  itemMap: Map<string, string>,
): Promise<{ orderMap: Map<string, string>; lineItemCount: number }> {
  const orderMap = new Map<string, string>();
  let lineItemCount = 0;

  for (const order of orders) {
    const customerDbId = order.customer?.id
      ? (customerMap.get(order.customer.id) ?? null)
      : null;
    const employeeDbId = order.employee?.id
      ? (employeeMap.get(order.employee.id) ?? null)
      : null;

    const orderResult = await client.query<{ id: string }>(
      `
        INSERT INTO public.clover_orders (
          merchant_id,
          clover_order_id,
          state,
          total,
          note,
          customer_id,
          employee_id,
          clover_created_time,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, now())
        ON CONFLICT (merchant_id, clover_order_id)
        DO UPDATE SET
          state = EXCLUDED.state,
          total = EXCLUDED.total,
          note = EXCLUDED.note,
          customer_id = EXCLUDED.customer_id,
          employee_id = EXCLUDED.employee_id,
          clover_created_time = EXCLUDED.clover_created_time,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
        RETURNING id
      `,
      [
        merchantId,
        order.id,
        order.state ?? null,
        order.total ?? null,
        order.note ?? null,
        customerDbId,
        employeeDbId,
        order.createdTime ?? null,
        order.modifiedTime ?? null,
        toJsonb(order),
      ],
    );

    const orderDbId = orderResult.rows[0].id;
    orderMap.set(order.id, orderDbId);

    if (order.lineItems?.elements?.length) {
      for (const lineItem of order.lineItems.elements) {
        const itemDbId = lineItem.item?.id
          ? (itemMap.get(lineItem.item.id) ?? null)
          : null;

        await client.query(
          `
            INSERT INTO public.clover_order_line_items (
              order_id,
              clover_line_item_id,
              item_id,
              name,
              price,
              quantity,
              clover_created_time,
              clover_modified_time,
              raw_payload
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb)
            ON CONFLICT (order_id, clover_line_item_id)
            DO UPDATE SET
              item_id = EXCLUDED.item_id,
              name = EXCLUDED.name,
              price = EXCLUDED.price,
              quantity = EXCLUDED.quantity,
              clover_created_time = EXCLUDED.clover_created_time,
              clover_modified_time = EXCLUDED.clover_modified_time,
              raw_payload = EXCLUDED.raw_payload
          `,
          [
            orderDbId,
            lineItem.id,
            itemDbId,
            lineItem.name ?? null,
            lineItem.price ?? null,
            lineItem.quantity ?? null,
            lineItem.createdTime ?? null,
            lineItem.modifiedTime ?? null,
            toJsonb(lineItem),
          ],
        );

        lineItemCount += 1;
      }
    }
  }

  return { orderMap, lineItemCount };
}

async function upsertPayments(
  client: PoolClient,
  merchantId: string,
  payments: CloverPayment[],
  orderMap: Map<string, string>,
  employeeMap: Map<string, string>,
): Promise<void> {
  for (const payment of payments) {
    const orderDbId = payment.order?.id ? (orderMap.get(payment.order.id) ?? null) : null;
    const employeeDbId = payment.employee?.id
      ? (employeeMap.get(payment.employee.id) ?? null)
      : null;

    await client.query(
      `
        INSERT INTO public.clover_payments (
          merchant_id,
          clover_payment_id,
          order_id,
          employee_id,
          amount,
          tip_amount,
          tax_amount,
          cashback_amount,
          result,
          tender_clover_id,
          tender_label,
          clover_created_time,
          clover_modified_time,
          raw_payload,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14::jsonb, now())
        ON CONFLICT (merchant_id, clover_payment_id)
        DO UPDATE SET
          order_id = EXCLUDED.order_id,
          employee_id = EXCLUDED.employee_id,
          amount = EXCLUDED.amount,
          tip_amount = EXCLUDED.tip_amount,
          tax_amount = EXCLUDED.tax_amount,
          cashback_amount = EXCLUDED.cashback_amount,
          result = EXCLUDED.result,
          tender_clover_id = EXCLUDED.tender_clover_id,
          tender_label = EXCLUDED.tender_label,
          clover_created_time = EXCLUDED.clover_created_time,
          clover_modified_time = EXCLUDED.clover_modified_time,
          raw_payload = EXCLUDED.raw_payload,
          updated_at = now()
      `,
      [
        merchantId,
        payment.id,
        orderDbId,
        employeeDbId,
        payment.amount,
        payment.tipAmount ?? null,
        payment.taxAmount ?? null,
        payment.cashbackAmount ?? null,
        payment.result ?? null,
        payment.tender?.id ?? null,
        payment.tender?.label ?? null,
        payment.createdTime ?? null,
        payment.modifiedTime ?? null,
        toJsonb(payment),
      ],
    );
  }
}

export async function syncCloverSnapshot(
  snapshot: CloverSyncSnapshot,
): Promise<CloverSyncResult> {
  return withTransaction(async (client) => {
    const merchantId = await upsertMerchant(client, snapshot);

    const customers = snapshot.customers ?? [];
    const employees = snapshot.employees ?? [];
    const categories = snapshot.categories ?? [];
    const discounts = snapshot.discounts ?? [];
    const items = snapshot.items ?? [];
    const stocks = snapshot.stocks ?? [];
    const orders = snapshot.orders ?? [];
    const payments = snapshot.payments ?? [];

    const customerMap = await upsertCustomers(client, merchantId, customers);
    const employeeMap = await upsertEmployees(client, merchantId, employees);
    const categoryMap = await upsertCategories(client, merchantId, categories);
    await upsertDiscounts(client, merchantId, discounts);
    const itemMap = await upsertItems(client, merchantId, items, categoryMap);
    await upsertStocks(client, stocks, itemMap);
    const { orderMap, lineItemCount } = await upsertOrders(
      client,
      merchantId,
      orders,
      customerMap,
      employeeMap,
      itemMap,
    );
    await upsertPayments(client, merchantId, payments, orderMap, employeeMap);

    return {
      merchantId,
      counts: {
        customers: customers.length,
        employees: employees.length,
        categories: categories.length,
        discounts: discounts.length,
        items: items.length,
        stocks: stocks.length,
        orders: orders.length,
        lineItems: lineItemCount,
        payments: payments.length,
      },
    };
  });
}
