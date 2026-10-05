import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().url(),
  CORS_ORIGINS: z.string().default(""),
  PHONE_LOOKUP_HMAC_SECRET: z.string().min(32),
  AUTH_JWT_SECRET: z.string().min(32),
  AUTH_JWT_ISSUER: z.string().url(),
  AUTH_JWT_AUDIENCE: z.string().min(1),
  DATA_ENCRYPTION_KEY: z.string().min(43).max(44),
});

export const env = envSchema.parse(process.env);
export const corsOrigins = env.CORS_ORIGINS.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

export const dataEncryptionKey = Buffer.from(env.DATA_ENCRYPTION_KEY, "base64");
if (dataEncryptionKey.length !== 32) {
  throw new Error("DATA_ENCRYPTION_KEY must be a base64-encoded 32-byte key.");
}
