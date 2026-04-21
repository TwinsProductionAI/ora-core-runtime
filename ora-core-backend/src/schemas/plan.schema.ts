import { z } from "zod";
import { ModuleTierSchema, OutputTypeSchema, PlanTierSchema } from "./common.schema.js";

export const PlanDefinitionSchema = z.object({
  id: PlanTierSchema,
  publicName: z.string().min(1),
  description: z.string().min(1),
  includedModuleTiers: z.array(ModuleTierSchema).min(1),
  allowedOutputs: z.array(OutputTypeSchema).min(1),
  visibleCapabilityIds: z.union([z.literal("all"), z.array(z.string().min(1))]),
  maxTokenEstimate: z.number().int().positive(),
  upgradeHint: z.string().optional()
});

export const PlanSeedSchema = z.array(PlanDefinitionSchema);
