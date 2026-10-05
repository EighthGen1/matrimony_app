import { Pool } from "pg";
import { env } from "./config";

export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  ssl: env.NODE_ENV === "production" ? { rejectUnauthorized: true } : undefined,
});

pool.on("error", (error) => {
  console.error("Unexpected PostgreSQL pool error", error);
});
