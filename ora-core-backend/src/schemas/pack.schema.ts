import { z } from "zod";
import { OutputTypeSchema, PlanTierSchema } from "./common.schema.js";

export const OraModulePackSchema = z.object({
  id: z.string().min(1),
  publicName: z.string().min(1),
  internalName: z.string().min(1),
  description: z.string().min(1),
  rationale: z.string().min(1),
  mandatory: z.boolean(),
  stable: z.boolean(),
  visibility: z.enum(["public", "private"]),
  minPlan: PlanTierSchema,
  includedModuleIds: z.array(z.string().min(1)).min(1),
  includedEssenceIds: z.array(z.string().min(1)).min(1),
  compatibleOutputs: z.array(OutputTypeSchema).min(1),
  tags: z.array(z.string().min(1)),
  status: z.enum(["active", "hidden", "deprecated"])
});

export const OraModulePackSeedSchema = z.array(OraModulePackSchema);
