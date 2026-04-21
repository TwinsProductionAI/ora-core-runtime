import type { PlanDefinition, PlanTier } from "../types/index.js";
import { PlanSeedSchema } from "../schemas/plan.schema.js";
import { notFound } from "../utils/errors.js";
import { readJsonSeed } from "../utils/read-json.js";

let planCache: PlanDefinition[] | null = null;

export function listPlanRegistry(): PlanDefinition[] {
  if (!planCache) {
    const seed = readJsonSeed<unknown>("src/billing/plans.seed.json");
    planCache = PlanSeedSchema.parse(seed);
  }

  return planCache;
}

export function getPlanById(planId: PlanTier): PlanDefinition {
  const plan = listPlanRegistry().find((item) => item.id === planId);

  if (!plan) {
    throw notFound(`Plan not found: ${planId}`);
  }

  return plan;
}
