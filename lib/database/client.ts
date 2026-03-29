import "server-only";
import { Pool } from "pg";

let pool: Pool | null = null;

/**
 * Get PostgreSQL connection pool for self-hosted database
 * Used for product catalog and inventory queries
 */
export function getPool(): Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;

    if (!connectionString) {
      throw new Error(
        "Missing DATABASE_URL environment variable. " +
          "Please ensure DATABASE_URL is set to your PostgreSQL connection string.",
      );
    }

    pool = new Pool({
      connectionString,
      max: 20, // Maximum number of clients in the pool
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
  }

  return pool;
}

/**
 * Execute a query using the PostgreSQL pool
 */
export async function query<T = any>(
  text: string,
  params?: any[],
): Promise<T[]> {
  try {
    const pool = getPool();
    const result = await pool.query(text, params);
    return result.rows;
  } catch (error: any) {
    console.error("[Database Query Error]:", {
      message: error.message,
      code: error.code,
      query: text.substring(0, 100) + "...",
    });
    // Re-throw so calling code can handle it
    throw error;
  }
}

/**
 * Close the database pool (useful for cleanup in tests or shutdown)
 */
export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
