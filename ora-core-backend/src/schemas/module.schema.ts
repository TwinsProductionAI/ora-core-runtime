import { z } from "zod";
import { ModuleStatusSchema, ModuleTierSchema, OutputTypeSchema, ValidationStateSchema } from "./common.schema.js";

export const OraModuleSchema = z.object({
  id: z.string().min(1),
  publicName: z.string().min(1),
  internalName: z.string().min(1),
  description: z.string().min(1),
  fullDescription: z.string().min(1),
  repoUrl: z.string().url(),
  category: z.string().min(1),
  tier: ModuleTierSchema,
  compatibleOutputs: z.array(OutputTypeSchema).min(1),
  dependencies: z.array(z.string().min(1)),
  conflicts: z.array(z.string().min(1)),
  tokenCostWeight: z.number().min(0),
  codeTemplate: z.string().min(1).optional(),
  tags: z.array(z.string().min(1)),
  status: ModuleStatusSchema,
  validationState: ValidationStateSchema
});

export const OraModuleSeedSchema = z.array(OraModuleSchema);