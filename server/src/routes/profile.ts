import { Router } from "express";
import { z } from "zod";
import { pool } from "../db";
import { requireAuthenticatedUser, type AuthenticatedRequest } from "../middleware/authenticate";
import { decryptPersonalData } from "../security/crypto";

export const profileRouter = Router();

const discoveryQuerySchema = z.object({
  page: z.coerce.number().int().min(1).max(10_000).default(1),
  pageSize: z.coerce.number().int().min(1).max(30).default(20),
  gender: z.enum(["female", "male", "other"]).optional(),
  minAge: z.coerce.number().int().min(18).max(100).optional(),
  maxAge: z.coerce.number().int().min(18).max(100).optional(),
  city: z.string().trim().min(1).max(100).optional(),
  state: z.string().trim().min(1).max(100).optional(),
  education: z.string().trim().min(1).max(120).optional(),
  verified: z.enum(["true", "false"]).optional(),
  sort: z.enum(["newest"]).default("newest"),
});

profileRouter.get("/", requireAuthenticatedUser, async (request: AuthenticatedRequest, response, next) => {
  const parsed = discoveryQuerySchema.safeParse(request.query);
  if (!parsed.success) {
    response.status(400).json({
      error: "INVALID_DISCOVERY_FILTERS",
      details: parsed.error.flatten(),
    });
    return;
  }

  const filters = parsed.data;
  if (
    filters.minAge !== undefined &&
    filters.maxAge !== undefined &&
    filters.minAge > filters.maxAge
  ) {
    response.status(400).json({ error: "INVALID_AGE_RANGE" });
    return;
  }

  try {
    const conditions = [
      "u.id <> $1",
      "u.account_status = 'active'",
      "u.deleted_at IS NULL",
      "p.visibility = 'visible'",
      `NOT EXISTS (
         SELECT 1
         FROM profile_blocks b
         WHERE (b.blocker_user_id = $1 AND b.blocked_user_id = u.id)
            OR (b.blocker_user_id = u.id AND b.blocked_user_id = $1)
       )`,
    ];
    const values: (string | number | boolean)[] = [request.user!.id];
    const addFilter = (condition: string, value: string | number | boolean) => {
      values.push(value);
      conditions.push(condition.replace("?", `$${values.length}`));
    };

    if (filters.gender) addFilter("u.gender = ?", filters.gender);
    if (filters.city) addFilter("lower(p.city) = lower(?)", filters.city);
    if (filters.state) addFilter("lower(p.state) = lower(?)", filters.state);
    if (filters.education) addFilter("lower(p.education) = lower(?)", filters.education);
    if (filters.minAge !== undefined) {
      addFilter(
        "extract(year from age((now() AT TIME ZONE 'Asia/Kolkata')::date, u.date_of_birth)) >= ?",
        filters.minAge,
      );
    }
    if (filters.maxAge !== undefined) {
      addFilter(
        "extract(year from age((now() AT TIME ZONE 'Asia/Kolkata')::date, u.date_of_birth)) <= ?",
        filters.maxAge,
      );
    }
    if (filters.verified !== undefined) {
      addFilter("u.verified_badge = ?", filters.verified === "true");
    }

    const whereClause = conditions.join("\n       AND ");
    const countQuery = pool.query(
      `SELECT count(*)::int AS total
       FROM users u
       JOIN profiles p ON p.user_id = u.id
       WHERE ${whereClause}`,
      values,
    );

    const offset = (filters.page - 1) * filters.pageSize;
    const pageValues = [...values, filters.pageSize, offset];
    const profilesQuery = pool.query(
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
         u.created_at
       FROM users u
       JOIN profiles p ON p.user_id = u.id
       WHERE ${whereClause}
       ORDER BY u.created_at DESC, u.id
       LIMIT $${values.length + 1}
       OFFSET $${values.length + 2}`,
      pageValues,
    );

    const [count, profiles] = await Promise.all([countQuery, profilesQuery]);
    response.json({
      items: profiles.rows.map((profile) => ({
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
        createdAt: profile.created_at,
      })),
      total: count.rows[0].total,
      page: filters.page,
      pageSize: filters.pageSize,
      hasMore: offset + profiles.rows.length < count.rows[0].total,
      sort: filters.sort,
    });
  } catch (error) {
    next(error);
  }
});

profileRouter.get("/:userId", requireAuthenticatedUser, async (request: AuthenticatedRequest, response, next) => {
  const parsedUserId = z.string().uuid().safeParse(request.params.userId);
  if (!parsedUserId.success) {
    response.status(400).json({ error: "INVALID_PROFILE_ID" });
    return;
  }

  try {
    const { rows } = await pool.query(
      `SELECT
         u.id,
         p.display_first_name,
         p.display_last_initial,
         u.gender,
         p.city,
         p.state,
         p.caste,
         p.education,
         EXISTS (
           SELECT 1
           FROM profile_shortlists s
           WHERE s.owner_user_id = $2 AND s.profile_user_id = u.id
         ) AS shortlisted
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
      [parsedUserId.data, request.user!.id],
    );

    const profile = rows[0];
    if (!profile) {
      response.status(404).json({ error: "PROFILE_NOT_FOUND" });
      return;
    }

    const viewerId = request.user?.id;
    const viewerHasPremium = viewerId
      ? await hasActiveSubscription(viewerId)
      : false;
    const canSeePremium = profile.id === viewerId || viewerHasPremium;

    const result: Record<string, unknown> = {
      id: profile.id,
      displayName: `${profile.display_first_name} ${profile.display_last_initial}.`,
      gender: profile.gender,
      city: profile.city,
      state: profile.state,
      caste: profile.caste,
      education: profile.education,
      premiumLocked: !canSeePremium,
      shortlisted: profile.shortlisted,
    };

    if (canSeePremium) {
      const premium = await pool.query(
        `SELECT u.phone_e164_encrypted, p.contact_email_encrypted
         FROM users u
         JOIN profiles p ON p.user_id = u.id
         WHERE u.id = $1`,
        [profile.id],
      );
      const encryptedContact = premium.rows[0];
      if (encryptedContact) {
        result.contact = {
          phone: decryptPersonalData(encryptedContact.phone_e164_encrypted),
          email: encryptedContact.contact_email_encrypted
            ? decryptPersonalData(encryptedContact.contact_email_encrypted)
            : null,
        };
      }
    }

    response.json(result);
  } catch (error) {
    next(error);
  }
});

async function hasActiveSubscription(userId: string): Promise<boolean> {
  const { rows } = await pool.query(
    `SELECT 1
     FROM subscriptions
     WHERE user_id = $1
       AND status = 'active'
       AND verified_at IS NOT NULL
       AND starts_at <= now()
       AND expires_at + interval '3 days' > now()
     LIMIT 1`,
    [userId],
  );
  return rows.length > 0;
}
