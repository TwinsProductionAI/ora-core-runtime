import { z } from "zod";
import { OutputTypeSchema, PlanTierSchema } from "./common.schema.js";

export const CapabilitySchema = z.object({
  id: z.string().min(1),
  label: z.string().min(1),
  description: z.string().min(1),
  mappedModules: z.array(z.string().min(1)).min(1),
  requiredPlan: PlanTierSchema,
  compatibleOutputs: z.array(OutputTypeSchema).min(1),
  tags: z.array(z.string().min(1)),
  status: z.enum(["active", "hidden", "deprecated"])
});

export const CapabilitySeedSchema = z.array(CapabilitySchema);