import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { errorMiddleware, notFoundMiddleware } from "./api/middleware/error.middleware.js";
import { env } from "./config/env.js";
import { router } from "./routes/index.js";

export function createApp() {
  const app = express();
  const corsOrigin = env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN.split(",").map((origin) => origin.trim());

  app.use(helmet());
  app.use(cors({ origin: corsOrigin }));
  app.use(express.json({ limit: "1mb" }));
  app.use(morgan(env.NODE_ENV === "production" ? "combined" : "dev"));

  app.use(router);
  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  return app;
}
