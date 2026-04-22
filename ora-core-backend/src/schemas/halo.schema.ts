import { z } from "zod";
import { OutputTypeSchema } from "./common.schema.js";

export const HaloDecisionSchema = z.enum(["ALLOW", "MODIFY", "REQUEST_EVIDENCE", "BLOCK", "TRACE_ONLY"]);
export const HaloDecisionOwnerSchema = z.enum(["PRIMORDIA", "RIME", "ECO_TWIN", "HALO_TRACECORE"]);

export const HaloAuditMetricsInputSchema = z
  .object({
    tokensEst: z.number().int().min(0).optional(),
    latencyMsMeasured: z.number().int().min(0).optional(),
    measured: z.boolean().default(false)
  })
  .default({ measured: false });

export const HaloAuditEventRequestSchema = z.object({
  sessionRef: z.string().min(1).optional(),
  inputRef: z.string().min(1).optional(),
  moduleIds: z.array(z.string().min(1)).default(["halo-tracecore"]),
  essenceIds: z.array(z.string().min(1)).default([]),
  outputType: OutputTypeSchema.default("direct"),
  governanceTrigger: z.string().min(1),
  decision: HaloDecisionSchema.default("TRACE_ONLY"),
  decisionOwner: HaloDecisionOwnerSchema.default("HALO_TRACECORE"),
  reasonShort: z.string().min(1).max(240),
  uncertaintyFlags: z.array(z.string().min(1)).default([]),
  metrics: HaloAuditMetricsInputSchema
});

export type HaloAuditEventRequest = z.infer<typeof HaloAuditEventRequestSchema>;
