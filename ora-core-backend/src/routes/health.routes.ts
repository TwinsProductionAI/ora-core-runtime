import { Router } from "express";
import { env } from "../config/env.js";
import { ok } from "../utils/http.js";

export const healthRouter = Router();

healthRouter.get("/health", (_req, res) => {
  return ok(res, {
    status: "ok",
    service: "ora-core-backend",
    version: "0.1.0",
    environment: env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});
