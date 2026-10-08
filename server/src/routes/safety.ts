import { Router } from "express";
import type { PoolClient } from "pg";
import { z } from "zod";
import { pool } from "../db";
import {
  requireAuthenticatedUser,
  type AuthenticatedRequest,
} from "../middleware/authenticate";

export const safetyRouter = Router();

const targetUserIdSchema = z.string().uuid();
const reportSchema = z.object({
  reason: z.enum([
    "fake_details",
    "inappropriate_content",
    "already_married",
    "other",
  ]),
  details: z.string().trim().max(2000).optional(),
});

function getTargetUserId(request: AuthenticatedRequest): string | undefined {
  const parsed = targetUserIdSchema.safeParse(request.params.userId);
  return parsed.success ? parsed.data : undefined;
}

async function visibleTargetExists(userId: string): Promise<boolean> {
  const result = await pool.query(
    `SELECT 1
     FROM users
     JOIN profiles ON profiles.user_id = users.id
     WHERE users.id = $1
       AND users.account_status = 'active'
       AND users.deleted_at IS NULL
       AND profiles.visibility = 'visible'`,
    [userId],
  );
  return result.rowCount === 1;
}

safetyRouter.get(
  "/shortlists",
  requireAuthenticatedUser,
  async (request: AuthenticatedRequest, response, next) => {
    try {
      const { rows } = await pool.query(
        `SELECT
           u.id,
           p.display_first_name,
           p.display_last_initial,
           extract(year from age((now() AT TIME ZONE 'Asia/Kolkata')::date, u.date_of_birth))::int AS age,
           u.gender,
           u.verified_badge,
           p.city,
           p.state,
           p.education,
           p.occupation,
           p.bio,
           s.created_at AS shortlisted_at
         FROM profile_shortlists s
         JOIN users u ON u.id = s.profile_user_id
         JOIN profiles p ON p.user_id = u.id
         WHERE s.owner_user_id = $1
           AND u.account_status = 'active'
           AND u.deleted_at IS NULL
           AND p.visibility = 'visible'
           AND NOT EXISTS (
             SELECT 1
             FROM profile_blocks b
             WHERE (b.blocker_user_id = $1 AND b.blocked_user_id = u.id)
                OR (b.blocker_user_id = u.id AND b.blocked_user_id = $1)
           )
         ORDER BY s.created_at DESC
         LIMIT 100`,
        [request.user!.id],
      );
      response.json({
        items: rows.map((profile) => ({
          id: profile.id,
          displayName: `${profile.display_first_name} ${profile.display_last_initial}.`,
          age: profile.age,
          gender: profile.gender,
          verified: profile.verified_badge,
          city: profile.city,
          state: profile.state,
          education: profile.education,
          occupation: profile.occupation,
          bio: profile.bio,
          shortlistedAt: profile.shortlisted_at,
        })),
      });
    } catch (error) {
      next(error);
    }
  },
);

safetyRouter.put(
  "/shortlists/:userId",
  requireAuthenticatedUser,
  async (request: AuthenticatedRequest, response, next) => {
    const targetId = getTargetUserId(request);
    if (!targetId) {
      response.status(400).json({ error: "INVALID_PROFILE_ID" });
      return;
    }
    if (targetId === request.user!.id) {
      response.status(400).json({ error: "CANNOT_SHORTLIST_SELF" });
      return;
    }

    try {
      if (!(await visibleTargetExists(targetId))) {
        response.status(404).json({ error: "PROFILE_NOT_FOUND" });
        return;
      }
      const { rowCount } = await pool.query(
        `INSERT INTO profile_shortlists (owner_user_id, profile_user_id)
         SELECT $1, $2
         WHERE NOT EXISTS (
           SELECT 1 FROM profile_blocks
           WHERE (blocker_user_id = $1 AND blocked_user_id = $2)
              OR (blocker_user_id = $2 AND blocked_user_id = $1)
         )
         ON CONFLICT (owner_user_id, profile_user_id) DO NOTHING`,
        [request.user!.id, targetId],
      );
      if (rowCount !== 1) {
        response.status(409).json({ error: "PROFILE_UNAVAILABLE_OR_SHORTLISTED" });
        return;
      }
      response.status(204).end();
    } catch (error) {
      next(error);
    }
  },
);

safetyRouter.delete(
  "/shortlists/:userId",
  requireAuthenticatedUser,
  async (request: AuthenticatedRequest, response, next) => {
    const targetId = getTargetUserId(request);
    if (!targetId) {
      response.status(400).json({ error: "INVALID_PROFILE_ID" });
      return;
    }
    try {
      await pool.query(
        "DELETE FROM profile_shortlists WHERE owner_user_id = $1 AND profile_user_id = $2",
        [request.user!.id, targetId],
      );
      response.status(204).end();
    } catch (error) {
      next(error);
    }
  },
);

safetyRouter.put(
  "/blocks/:userId",
  requireAuthenticatedUser,
  async (request: AuthenticatedRequest, response, next) => {
    const targetId = getTargetUserId(request);
    if (!targetId) {
      response.status(400).json({ error: "INVALID_PROFILE_ID" });
      return;
    }
    if (targetId === request.user!.id) {
      response.status(400).json({ error: "CANNOT_BLOCK_SELF" });
      return;
    }

    try {
      if (!(await visibleTargetExists(targetId))) {
        response.status(404).json({ error: "PROFILE_NOT_FOUND" });
        return;
      }
      const client: PoolClient = await pool.connect();
      try {
        await client.query("BEGIN");
        await client.query(
        `INSERT INTO profile_blocks (blocker_user_id, blocked_user_id)
         VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
        [request.user!.id, targetId],
        );
        await client.query(
        `DELETE FROM profile_shortlists
         WHERE (owner_user_id = $1 AND profile_user_id = $2)
            OR (owner_user_id = $2 AND profile_user_id = $1)`,
        [request.user!.id, targetId],
        );
        await client.query(
        `DELETE FROM interests
         WHERE (sender_id = $1 AND receiver_id = $2)
            OR (sender_id = $2 AND receiver_id = $1)`,
        [request.user!.id, targetId],
        );
        await client.query("COMMIT");
      } catch (error) {
        await client.query("ROLLBACK");
        throw error;
      } finally {
        client.release();
      }
      response.status(204).end();
    } catch (error) {
      next(error);
    }
  },
);

safetyRouter.delete(
  "/blocks/:userId",
  requireAuthenticatedUser,
  async (request: AuthenticatedRequest, response, next) => {
    const targetId = getTargetUserId(request);
    if (!targetId) {
      response.status(400).json({ error: "INVALID_PROFILE_ID" });
      return;
    }
    try {
      await pool.query(
        "DELETE FROM profile_blocks WHERE blocker_user_id = $1 AND blocked_user_id = $2",
        [request.user!.id, targetId],
      );
      response.status(204).end();
    } catch (error) {
      next(error);
    }
  },
);

safetyRouter.post(
  "/profiles/:userId/report",
  requireAuthenticatedUser,
  async (request: AuthenticatedRequest, response, next) => {
    const targetId = getTargetUserId(request);
    if (!targetId) {
      response.status(400).json({ error: "INVALID_PROFILE_ID" });
      return;
    }
    if (targetId === request.user!.id) {
      response.status(400).json({ error: "CANNOT_REPORT_SELF" });
      return;
    }
    const parsed = reportSchema.safeParse(request.body);
    if (!parsed.success) {
      response.status(400).json({
        error: "INVALID_REPORT",
        details: parsed.error.flatten(),
      });
      return;
    }

    try {
      if (!(await visibleTargetExists(targetId))) {
        response.status(404).json({ error: "PROFILE_NOT_FOUND" });
        return;
      }
      const created = await pool.query(
        `INSERT INTO profile_reports (reporter_id, reported_user_id, reason, details)
         VALUES ($1, $2, $3, $4)
         RETURNING id, status, created_at`,
        [
          request.user!.id,
          targetId,
          parsed.data.reason,
          parsed.data.details || null,
        ],
      );
      response.status(201).json(created.rows[0]);
    } catch (error) {
      next(error);
    }
  },
);
