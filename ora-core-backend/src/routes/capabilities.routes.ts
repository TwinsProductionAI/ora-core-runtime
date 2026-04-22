import { Router } from "express";
import { OutputTypeSchema, PlanTierSchema } from "../schemas/common.schema.js";
import { listCapabilities, verifyCapabilityGraph } from "../services/capability.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const capabilitiesRouter = Router();

capabilitiesRouter.get(
  "/capabilities",
  asyncHandler((req, res) => {
    const planParse = PlanTierSchema.optional().safeParse(req.query.planId);
    const outputParse = OutputTypeSchema.optional().safeParse(req.query.outputType);
    const planId = planParse.success ? planParse.data : undefined;
    const outputType = outputParse.success ? outputParse.data : undefined;
    const capabilities = listCapabilities(planId).filter((capability) =>
      outputType ? capability.compatibleOutputs.includes(outputType) : true
    );

    return ok(res, capabilities);
  })
);

capabilitiesRouter.get(
  "/capabilities/graph",
  asyncHandler((req, res) => {
    const ids = typeof req.query.ids === "string" ? req.query.ids.split(",").filter(Boolean) : [];
    return ok(res, verifyCapabilityGraph(ids));
  })
);