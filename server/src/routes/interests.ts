import { Router } from "express";
import type { PoolClient } from "pg";
import { z } from "zod";
import { pool } from "../db";
import { requireAuthenticatedUser, type AuthenticatedRequest } from "../middleware/authenticate";

export const interestsRouter = Router();

const createInterestSchema = z.object({
  receiverId: z.string().uuid(),
});

interestsRouter.post("/", requireAuthenticatedUser, async (request: AuthenticatedRequest, response, next) => {
  const parsed = createInterestSchema.safeParse(request.body);
  if (!parsed.success) {
    response.status(400).json({ error: "INVALID_REQUEST", details: parsed.error.flatten() });
    return;
  }

  const senderId = request.user?.id;
  if (!senderId) {
    response.status(401).json({ error: "AUTHENTICATION_REQUIRED" });
    return;
  }
  const { receiverId } = parsed.data;
  if (senderId === receiverId) {
    response.status(400).json({ error: "CANNOT_INTEREST_SELF" });
    return;
  }

  let client: PoolClient | undefined;
  let transactionOpen = false;
  try {
    client = await pool.connect();
    await client.query("BEGIN");
    transactionOpen = true;
    await client.query("SELECT pg_advisory_xact_lock(hashtextextended($1, 0))", [senderId]);

    const receiver = await client.query(
      `SELECT 1
       FROM users u
       JOIN profiles p ON p.user_id = u.id
       WHERE u.id = $1
         AND u.account_status = 'active'
         AND u.deleted_at IS NULL
         AND p.visibility = 'visible'
         AND NOT EXISTS (
           SELECT 1
           FROM profile_blocks b
           WHERE (b.blocker_user_id = $2 AND b.blocked_user_id = u.id)
              OR (b.blocker_user_id = u.id AND b.blocked_user_id = $2)
         )`,
      [receiverId, senderId],
    );
    if (receiver.rows.length !== 1) {
      await client.query("ROLLBACK");
      transactionOpen = false;
      response.status(404).json({ error: "PROFILE_NOT_FOUND" });
      return;
    }

    const premium = await client.query(
      `SELECT 1
       FROM subscriptions
       WHERE user_id = $1
         AND status = 'active'
         AND verified_at IS NOT NULL
         AND starts_at <= now()
         AND expires_at + interval '3 days' > now()
       LIMIT 1`,
      [senderId],
    );
    if (premium.rows.length === 0) {
      const dailyCount = await client.query(
        `SELECT count(*)::int AS count
         FROM interests
         WHERE sender_id = $1
           AND created_at >= ((now() AT TIME ZONE 'Asia/Kolkata')::date::timestamp AT TIME ZONE 'Asia/Kolkata')`,
        [senderId],
      );
      if (dailyCount.rows[0].count >= 5) {
        await client.query("ROLLBACK");
        transactionOpen = false;
        response.status(429).json({ error: "DAILY_INTEREST_LIMIT_REACHED" });
        return;
      }
    }

    const created = await client.query(
      `INSERT INTO interests (sender_id, receiver_id)
       VALUES ($1, $2)
       ON CONFLICT (sender_id, receiver_id) DO NOTHING
       RETURNING id, status, created_at`,
      [senderId, receiverId],
    );
    if (created.rows.length !== 1) {
      await client.query("ROLLBACK");
      transactionOpen = false;
      response.status(409).json({ error: "INTEREST_ALREADY_EXISTS" });
      return;
    }

    await client.query("COMMIT");
    transactionOpen = false;
    response.status(201).json(created.rows[0]);
  } catch (error) {
    if (client && transactionOpen) {
      try {
        await client.query("ROLLBACK");
      } catch (rollbackError) {
        next(new AggregateError([error, rollbackError], "Interest transaction and rollback both failed."));
        return;
      }
    }
    next(error);
  } finally {
    client?.release();
  }
});
