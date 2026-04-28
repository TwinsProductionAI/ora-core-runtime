import { z } from "zod";
import { OutputTypeSchema } from "./common.schema.js";

export const EssenceMeStakesLevelSchema = z.enum(["low", "medium", "high"]);
export const EssenceMeUncertaintyClassSchema = z.enum([
  "data_missing",
  "context_missing",
  "reasoning_block",
  "conflict",
  "overcomplexity",
  "low_value_continuation"
]);
export const EssenceMeMinimalActionSchema = z.enum([
  "answer_now",
  "ask_one_question",
  "search_web",
  "search_files",
  "simplify_scope",
  "produce_partial",
  "stop_clean"
]);

export const EssenceMeCycleSchema = z.object({
  summary: z.string().min(1),
  newInformation: z.array(z.string().min(1)).default([]),
  toolsUsed: z.array(z.string().min(1)).default([]),
  openQuestions: z.array(z.string().min(1)).default([]),
  uncertaintyHints: z.array(z.string().min(1)).default([]),
  actionTaken: z.string().min(1).optional()
});

export const EssenceMeAnalyzeRequestSchema = z.object({
  userRequest: z.string().min(1),
  outputType: OutputTypeSchema.default("direct"),
  cycles: z.array(EssenceMeCycleSchema).min(1),
  known: z.array(z.string().min(1)).default([]),
  unknown: z.array(z.string().min(1)).default([]),
  blockers: z.array(z.string().min(1)).default([]),
  risks: z.array(z.string().min(1)).default([]),
  stakesLevel: EssenceMeStakesLevelSchema.default("low"),
  allowSearchWeb: z.boolean().default(true),
  allowSearchFiles: z.boolean().default(true)
});

export type EssenceMeAnalyzeRequest = z.infer<typeof EssenceMeAnalyzeRequestSchema>;
export type EssenceMeUncertaintyClass = z.infer<typeof EssenceMeUncertaintyClassSchema>;
export type EssenceMeMinimalAction = z.infer<typeof EssenceMeMinimalActionSchema>;