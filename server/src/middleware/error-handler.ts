import type { ErrorRequestHandler } from "express";

export const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => {
  console.error("Unhandled API error", error);
  response.status(500).json({ error: "INTERNAL_SERVER_ERROR" });
};
