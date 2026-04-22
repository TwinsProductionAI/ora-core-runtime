import { createHash } from "node:crypto";
import type { HaloAuditEvent, HaloAuditMetrics, OutputType } from "../types/index.js";
import type { HaloAuditEventRequest } from "../schemas/halo.schema.js";
import { getEssenceById } from "../essences/registry.js";
import { getModuleById } from "../modules/registry.js";
import { resolveEssenceBundle } from "./essence.service.js";

const WH_PER_TOKEN_BASELINE = 0.01835;
const CO2EQ_G_PER_WH_BASELINE = 0.392;

export const haloTraceCoreSpec = {
  moduleId: "halo-tracecore",
  publicName: "HALO TraceCore",
  version: "3.1.0-essence-trace",
  role: "Trace governance decisions, active essences, and estimated energy without storing sensitive raw prompt content.",
  metricPolicy: "Metrics are estimates unless measured=true and a real runtime measurement is supplied.",
  privacyPolicy: "sessionRef and inputRef are hashed with sha256 before being emitted.",
  baselines: {
    whPerToken: WH_PER_TOKEN_BASELINE,
    co2eqGPerWh: CO2EQ_G_PER_WH_BASELINE
  }
} as const;

export function createHaloAuditEvent(input: HaloAuditEventRequest): HaloAuditEvent {
  const modulesActive = normalizeModuleIds(input.moduleIds);
  const essencesActive = resolveEssenceIds(modulesActive, input.essenceIds, input.outputType);
  const metrics = buildMetrics(input.metrics);
  const uncertaintyFlags = normalizeUncertaintyFlags(input.uncertaintyFlags, metrics);
  const timestamp = new Date().toISOString();

  const eventPayload = {
    timestamp,
    sessionRef: hashReference(input.sessionRef ?? "session:redacted"),
    inputRef: hashReference(input.inputRef ?? "input:redacted"),
    essencesActive,
    modulesActive,
    governanceTrigger: input.governanceTrigger,
    decision: input.decision,
    decisionOwner: input.decisionOwner,
    reasonShort: input.reasonShort,
    uncertaintyFlags,
    metrics
  };
  const traceHash = sha256(stableStringify(eventPayload));

  return {
    eventId: `halo_${traceHash.slice(0, 12)}`,
    ...eventPayload,
    traceHash
  };
}

function normalizeModuleIds(moduleIds: string[]): string[] {
  const ids = new Set(["halo-tracecore", ...moduleIds]);

  for (const moduleId of ids) {
    getModuleById(moduleId);
  }

  return [...ids].sort();
}

function resolveEssenceIds(moduleIds: string[], essenceIds: string[], outputType: OutputType): string[] {
  const ids = new Set<string>();

  for (const essence of resolveEssenceBundle(moduleIds, outputType).essences) {
    ids.add(essence.essenceId);
  }

  for (const essenceId of essenceIds) {
    getEssenceById(essenceId);
    ids.add(essenceId);
  }

  return [...ids].sort();
}

function buildMetrics(input: HaloAuditEventRequest["metrics"]): HaloAuditMetrics {
  const energyWhEst = typeof input.tokensEst === "number" ? round(input.tokensEst * WH_PER_TOKEN_BASELINE) : undefined;
  const co2eqGEst = typeof energyWhEst === "number" ? round(energyWhEst * CO2EQ_G_PER_WH_BASELINE) : undefined;

  return {
    tokensEst: input.tokensEst,
    energyWhEst,
    co2eqGEst,
    latencyMsMeasured: input.latencyMsMeasured,
    measured: input.measured
  };
}

function normalizeUncertaintyFlags(flags: string[], metrics: HaloAuditMetrics): string[] {
  const normalized = new Set(flags);

  if (!metrics.measured) {
    normalized.add("METRICS_ESTIMATED");
  }

  if (typeof metrics.tokensEst !== "number") {
    normalized.add("TOKENS_NOT_SUPPLIED");
  }

  return [...normalized].sort();
}

function hashReference(value: string): string {
  return `sha256:${sha256(value)}`;
}

function sha256(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function stableStringify(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }

  if (value && typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>)
      .filter(([, entryValue]) => entryValue !== undefined)
      .sort(([left], [right]) => left.localeCompare(right));

    return `{${entries.map(([key, entryValue]) => `${JSON.stringify(key)}:${stableStringify(entryValue)}`).join(",")}}`;
  }

  return JSON.stringify(value);
}

function round(value: number): number {
  return Math.round(value * 1_000_000) / 1_000_000;
}
