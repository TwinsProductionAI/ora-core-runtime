import type { Capability, PlanTier } from "../types/index.js";
import { getCapabilitiesByIds, listCapabilityRegistry } from "../capabilities/registry.js";
import { getModuleById, resolveModuleDependencies } from "../modules/registry.js";
import { canSeeCapability } from "./plan.service.js";

export function listCapabilities(planId?: PlanTier): Capability[] {
  const capabilities = listCapabilityRegistry().filter((capability) => capability.status === "active");

  if (!planId) {
    return capabilities;
  }

  return capabilities.filter((capability) => canSeeCapability(planId, capability));
}

export function getCapabilities(capabilityIds: string[]): Capability[] {
  return getCapabilitiesByIds(capabilityIds);
}

export function getActivatedModuleIds(capabilityIds: string[]): string[] {
  const modules = new Set<string>();

  for (const capability of getCapabilities(capabilityIds)) {
    for (const moduleId of capability.activatesModules) {
      modules.add(moduleId);
    }
  }

  return [...modules];
}

export function verifyCapabilityGraph(capabilityIds: string[]) {
  const activatedModuleIds = getActivatedModuleIds(capabilityIds);
  const dependencies = resolveModuleDependencies(activatedModuleIds);
  const allModules = [...activatedModuleIds, ...dependencies.map((module) => module.id)].map((moduleId) =>
    getModuleById(moduleId)
  );

  const conflicts = allModules.flatMap((module) =>
    module.conflicts
      .filter((conflictId) => allModules.some((candidate) => candidate.id === conflictId))
      .map((conflictId) => ({
        moduleId: module.id,
        conflictsWith: conflictId,
        reason: `${module.id} declares a conflict with ${conflictId}`
      }))
  );

  return {
    activatedModuleIds,
    dependencies,
    conflicts
  };
}
