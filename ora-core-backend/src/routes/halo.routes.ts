import { Router } from "express";
import { validateBody } from "../api/middleware/validation.middleware.js";
import { HaloAuditEventRequestSchema } from "../schemas/halo.schema.js";
import { createHaloAuditEvent, haloTraceCoreSpec } from "../services/halo.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const haloRouter = Router();

haloRouter.get(
  "/halo/spec",
  asyncHandler((_req, res) => ok(res, haloTraceCoreSpec))
);

haloRouter.post(
  "/halo/audit-events",
  validateBody(HaloAuditEventRequestSchema),
  asyncHandler((req, res) => ok(res, createHaloAuditEvent(req.body)))
);
