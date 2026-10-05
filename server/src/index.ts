import cors from "cors";
import express from "express";
import helmet from "helmet";
import { env, corsOrigins } from "./config";
import { errorHandler } from "./middleware/error-handler";
import { healthRouter } from "./routes/health";
import { interestsRouter } from "./routes/interests";
import { profileRouter } from "./routes/profile";

const app = express();
app.disable("x-powered-by");
app.use(helmet());
app.use(cors({
  origin: corsOrigins.length === 0 ? false : corsOrigins,
  methods: ["GET", "POST", "PATCH", "DELETE"],
  allowedHeaders: ["Authorization", "Content-Type"],
}));
app.use(express.json({ limit: "32kb" }));
app.use("/health", healthRouter);
app.use("/api/v1/interests", interestsRouter);
app.use("/api/v1/profiles", profileRouter);
app.use(errorHandler);

const server = app.listen(env.PORT, () => {
  console.info(`Anbu Matrimony API listening on port ${env.PORT}`);
});

async function shutdown(signal: string): Promise<void> {
  console.info(`Received ${signal}; shutting down`);
  server.close((error) => {
    if (error) {
      console.error("HTTP server shutdown failed", error);
      process.exitCode = 1;
    }
    process.exit();
  });
}

process.on("SIGTERM", () => void shutdown("SIGTERM"));
process.on("SIGINT", () => void shutdown("SIGINT"));
