import { z } from "zod";
import { EssenceTypeSchema, OutputTypeSchema } from "./common.schema.js";

export const ModuleEssenceSchema = z.object({
  essenceId: z.string().min(1),
  moduleId: z.string().min(1),
  essenceType: EssenceTypeSchema,
  targetOutputs: z.array(OutputTypeSchema).min(1),
  priority: z.number().int().min(0),
  compressionLevel: z.number().int().min(0).max(3),
  injectableContent: z.string().min(1),
  dependencies: z.array(z.string().min(1)),
  conflicts: z.array(z.string().min(1)),
  tokenWeight: z.number().min(0)
});

export const ModuleEssenceSeedSchema = z.array(ModuleEssenceSchema);