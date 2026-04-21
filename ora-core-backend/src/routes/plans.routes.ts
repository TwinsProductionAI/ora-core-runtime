import { Router } from "express";
import { listPlans } from "../services/plan.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const plansRouter = Router();

plansRouter.get("/plans", asyncHandler((_req, res) => ok(res, listPlans())));
