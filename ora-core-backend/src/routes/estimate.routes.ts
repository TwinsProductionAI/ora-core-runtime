import { Router } from "express";
import { validateBody } from "../api/middleware/validation.middleware.js";
import { EstimateTokensRequestSchema } from "../schemas/request.schema.js";
import { estimateTokenCost } from "../services/token-estimator.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const estimateRouter = Router();

estimateRouter.post(
  "/estimate/tokens",
  validateBody(EstimateTokensRequestSchema),
  asyncHandler((req, res) => ok(res, estimateTokenCost(req.body)))
);
