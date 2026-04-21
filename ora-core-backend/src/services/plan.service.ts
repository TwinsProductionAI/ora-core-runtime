import type { Capability, OraModule, OutputType, PlanDefinition, PlanTier } from "../types/index.js";
import { getPlanById, listPlanRegistry } from "../billing/plan.registry.js";

export function listPlans(): PlanDefinition[] {
  return listPlanRegistry();
}

export function getPlan(planId: PlanTier): PlanDefinition {
  return getPlanById(planId);
}

export function canUseModule(planId: PlanTier, module: OraModule): boolean {
  const plan = getPlan(planId);
  return plan.includedModuleTiers.includes(module.tier);
}

export function canUseOutput(planId: PlanTier, outputType: OutputType): boolean {
  const plan = getPlan(planId);
  return plan.allowedOutputs.includes(outputType);
}

export function canSeeCapability(planId: PlanTier, capability: Capability): boolean {
  const plan = getPlan(planId);

  if (plan.visibleCapabilityIds === "all") {
    return capability.visibleToPlans.includes(planId);
  }

  return plan.visibleCapabilityIds.includes(capability.id) && capability.visibleToPlans.includes(planId);
}
