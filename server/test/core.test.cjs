const { before } = require("node:test");
const assert = require("node:assert/strict");

before(() => {
  process.env.NODE_ENV = "test";
  process.env.DATABASE_URL = "postgres://anbu:test@localhost:5432/anbu";
  process.env.PHONE_LOOKUP_HMAC_SECRET = "test-phone-lookup-secret-at-least-32";
  process.env.AUTH_JWT_SECRET = "test-auth-jwt-secret-at-least-32-bytes";
  process.env.AUTH_JWT_ISSUER = "https://auth.test.example";
  process.env.AUTH_JWT_AUDIENCE = "anbu-matrimony-api";
  process.env.DATA_ENCRYPTION_KEY = Buffer.alloc(32, 7).toString("base64");
});

const { test } = require("node:test");

test("personal-data encryption round-trips and authenticates ciphertext", () => {
  const { decryptPersonalData, encryptPersonalData } = require("../dist/security/crypto");
  const encrypted = encryptPersonalData("+919876543210");
  assert.equal(decryptPersonalData(encrypted), "+919876543210");
  assert.throws(() => decryptPersonalData(`${encrypted.slice(0, -2)}ab`));
});

test("phone lookup uses a stable keyed digest", () => {
  const { phoneLookupHash } = require("../dist/security/crypto");
  const phone = "+919876543210";
  assert.equal(phoneLookupHash(phone), phoneLookupHash(phone));
  assert.notEqual(phoneLookupHash(phone), phoneLookupHash("+919876543211"));
  assert.notEqual(phoneLookupHash(phone), phone);
});

test("age eligibility applies India-local thresholds and rejects invalid dates", () => {
  const { isEligibleByAge } = require("../dist/domain/eligibility");
  assert.equal(isEligibleByAge("female", "1990-01-01"), true);
  assert.equal(isEligibleByAge("male", "1990-01-01"), true);
  assert.equal(isEligibleByAge("female", "2010-01-01"), false);
  assert.equal(isEligibleByAge("male", "2010-01-01"), false);
  assert.equal(isEligibleByAge("female", "2010-02-31"), false);
  assert.equal(isEligibleByAge("female", "01-01-1990"), false);
});
