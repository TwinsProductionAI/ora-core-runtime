import { Router } from "express";
import { validateBody } from "../api/middleware/validation.middleware.js";
import { AnalyzeNeedRequestSchema } from "../schemas/request.schema.js";
import { analyzeNeed } from "../services/orchestrator.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const needsRouter = Router();

needsRouter.post(
  "/needs/analyze",
  validateBody(AnalyzeNeedRequestSchema),
  asyncHandler((req, res) => ok(res, analyzeNeed(req.body)))
);
