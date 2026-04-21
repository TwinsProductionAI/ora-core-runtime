import { Router } from "express";
import { validateBody } from "../api/middleware/validation.middleware.js";
import { SelectionResolveRequestSchema } from "../schemas/request.schema.js";
import { resolveSelection } from "../services/orchestrator.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const selectionRouter = Router();

selectionRouter.post(
  "/selection/resolve",
  validateBody(SelectionResolveRequestSchema),
  asyncHandler((req, res) => ok(res, resolveSelection(req.body)))
);
