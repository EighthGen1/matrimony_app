import { Router } from "express";
import { z } from "zod";
import { pool } from "../db";
import { requireAuthenticatedUser, type AuthenticatedRequest } from "../middleware/authenticate";
import { decryptPersonalData } from "../security/crypto";

export const profileRouter = Router();

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
         p.education
       FROM users u
       JOIN profiles p ON p.user_id = u.id
       WHERE u.id = $1
         AND u.account_status = 'active'
         AND u.deleted_at IS NULL
         AND p.visibility = 'visible'`,
      [parsedUserId.data],
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
