import { z } from "zod";
import { ClientContextSchema, OutputTypeSchema, PlanTierSchema } from "./common.schema.js";

export const AnalyzeNeedRequestSchema = z.object({
  userRequest: z.string().min(1),
  clientContext: ClientContextSchema.optional()
});

export const SelectionResolveRequestSchema = z.object({
  userRequest: z.string().min(1),
  planId: PlanTierSchema.default("free"),
  selectedCapabilityIds: z.array(z.string().min(1)).default([]),
  selectedModuleIds: z.array(z.string().min(1)).default([]),
  clientContext: ClientContextSchema.optional()
});

export const CompileRequestSchema = z.object({
  userRequest: z.string().min(1),
  title: z.string().min(1).optional(),
  planId: PlanTierSchema.default("free"),
  selectedCapabilityIds: z.array(z.string().min(1)).default([]),
  selectedModuleIds: z.array(z.string().min(1)).default([]),
  clientContext: ClientContextSchema.optional()
});

export const EstimateTokensRequestSchema = z.object({
  userRequest: z.string().min(1),
  outputType: OutputTypeSchema.default("direct"),
  selectedCapabilityIds: z.array(z.string().min(1)).default([]),
  selectedModuleIds: z.array(z.string().min(1)).default([])
});

export type AnalyzeNeedRequest = z.infer<typeof AnalyzeNeedRequestSchema>;
export type SelectionResolveRequest = z.infer<typeof SelectionResolveRequestSchema>;
export type CompileRequest = z.infer<typeof CompileRequestSchema>;
export type EstimateTokensRequest = z.infer<typeof EstimateTokensRequestSchema>;
