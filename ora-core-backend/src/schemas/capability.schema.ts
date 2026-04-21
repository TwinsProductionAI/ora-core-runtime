import { z } from "zod";
import { PlanTierSchema } from "./common.schema.js";

export const CapabilitySchema = z.object({
  id: z.string().min(1),
  publicName: z.string().min(1),
  description: z.string().min(1),
  visibleToPlans: z.array(PlanTierSchema).min(1),
  activatesModules: z.array(z.string().min(1)).min(1),
  tags: z.array(z.string().min(1)),
  status: z.enum(["active", "hidden", "deprecated"])
});

export const CapabilitySeedSchema = z.array(CapabilitySchema);
