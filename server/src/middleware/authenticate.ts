import jwt from "jsonwebtoken";
import type { NextFunction, Request, Response } from "express";
import { env } from "../config";
import { pool } from "../db";

export interface AuthenticatedRequest extends Request {
  user?: { id: string };
}

export async function requireAuthenticatedUser(
  request: AuthenticatedRequest,
  response: Response,
  next: NextFunction,
): Promise<void> {
  const authorization = request.header("authorization");
  const token = authorization?.match(/^Bearer\s+([^\s]+)$/i)?.[1];
  if (!token) {
    response.status(401).json({ error: "AUTHENTICATION_REQUIRED" });
    return;
  }

  let subject: string;
  try {
    const payload = jwt.verify(token, env.AUTH_JWT_SECRET, {
      algorithms: ["HS256"],
      issuer: env.AUTH_JWT_ISSUER,
      audience: env.AUTH_JWT_AUDIENCE,
      maxAge: "15m",
    });
    if (
      typeof payload === "string" ||
      typeof payload.sub !== "string" ||
      typeof payload.exp !== "number" ||
      typeof payload.iat !== "number"
    ) {
      response.status(401).json({ error: "INVALID_ACCESS_TOKEN" });
      return;
    }
    subject = payload.sub;
  } catch {
    response.status(401).json({ error: "INVALID_ACCESS_TOKEN" });
    return;
  }

  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(subject)) {
    response.status(401).json({ error: "INVALID_ACCESS_TOKEN" });
    return;
  }

  try {
    const { rowCount } = await pool.query(
      `SELECT 1
       FROM users
       WHERE id = $1
         AND account_status = 'active'
         AND phone_verified_at IS NOT NULL
         AND deleted_at IS NULL`,
      [subject],
    );
    if (rowCount !== 1) {
      response.status(401).json({ error: "ACCOUNT_NOT_ACTIVE" });
      return;
    }
    request.user = { id: subject };
    next();
  } catch (error) {
    next(error);
  }
}
