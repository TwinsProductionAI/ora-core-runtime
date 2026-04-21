import { z } from "zod";
import {
  moduleStatusValues,
  moduleTierValues,
  outputTypeValues,
  planTierValues,
  validationStateValues
} from "../types/index.js";

export const ModuleTierSchema = z.enum(moduleTierValues);
export const PlanTierSchema = z.enum(planTierValues);
export const OutputTypeSchema = z.enum(outputTypeValues);
export const ModuleStatusSchema = z.enum(moduleStatusValues);
export const ValidationStateSchema = z.enum(validationStateValues);

export const ClientContextSchema = z
  .object({
    audience: z.string().min(1).optional(),
    projectType: z.string().min(1).optional(),
    constraints: z.array(z.string().min(1)).default([]),
    selectedCapabilityIds: z.array(z.string().min(1)).default([]),
    preferredOutput: OutputTypeSchema.optional()
  })
  .partial()
  .default({});
