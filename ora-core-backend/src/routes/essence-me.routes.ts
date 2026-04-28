import { Router } from "express";
import { validateBody } from "../api/middleware/validation.middleware.js";
import { EssenceMeAnalyzeRequestSchema } from "../schemas/essence-me.schema.js";
import { analyzeEssenceMe, essenceMeSpec } from "../services/essence-me.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const essenceMeRouter = Router();

essenceMeRouter.get(
  "/essence-me/spec",
  asyncHandler((_req, res) => ok(res, essenceMeSpec))
);

essenceMeRouter.post(
  "/essence-me/analyze",
  validateBody(EssenceMeAnalyzeRequestSchema),
  asyncHandler((req, res) => ok(res, analyzeEssenceMe(req.body)))
);