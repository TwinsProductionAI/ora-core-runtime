import { Router } from "express";
import { PlanTierSchema } from "../schemas/common.schema.js";
import { listCapabilities, verifyCapabilityGraph } from "../services/capability.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const capabilitiesRouter = Router();

capabilitiesRouter.get(
  "/capabilities",
  asyncHandler((req, res) => {
    const planParse = PlanTierSchema.optional().safeParse(req.query.planId);
    const planId = planParse.success ? planParse.data : undefined;

    return ok(res, listCapabilities(planId));
  })
);

capabilitiesRouter.get(
  "/capabilities/graph",
  asyncHandler((req, res) => {
    const ids = typeof req.query.ids === "string" ? req.query.ids.split(",").filter(Boolean) : [];
    return ok(res, verifyCapabilityGraph(ids));
  })
);
