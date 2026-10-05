import { createCipheriv, createDecipheriv, createHmac, randomBytes } from "node:crypto";
import { dataEncryptionKey, env } from "../config";

export function encryptPersonalData(plainText: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", dataEncryptionKey, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, "utf8"), cipher.final()]);
  return [
    "v1",
    iv.toString("base64url"),
    cipher.getAuthTag().toString("base64url"),
    encrypted.toString("base64url"),
  ].join(".");
}

export function decryptPersonalData(envelope: string): string {
  const [version, ivEncoded, tagEncoded, payloadEncoded] = envelope.split(".");
  if (version !== "v1" || !ivEncoded || !tagEncoded || !payloadEncoded) {
    throw new Error("Invalid encrypted personal-data envelope.");
  }
  const decipher = createDecipheriv("aes-256-gcm", dataEncryptionKey, Buffer.from(ivEncoded, "base64url"));
  decipher.setAuthTag(Buffer.from(tagEncoded, "base64url"));
  return Buffer.concat([
    decipher.update(Buffer.from(payloadEncoded, "base64url")),
    decipher.final(),
  ]).toString("utf8");
}

export function phoneLookupHash(e164Phone: string): string {
  return createHmac("sha256", env.PHONE_LOOKUP_HMAC_SECRET)
    .update(e164Phone)
    .digest("hex");
}
