import type { EssenceBundle, EssenceConflict, ModuleEssence, OutputType } from "../types/index.js";
import { getEssenceById, getEssencesByModuleIds, listEssenceRegistry } from "../essences/registry.js";

export function listEssences(outputType?: OutputType): ModuleEssence[] {
  const essences = listEssenceRegistry();
  return outputType ? essences.filter((essence) => essence.targetOutputs.includes(outputType)) : essences;
}

export function resolveEssenceBundle(moduleIds: string[], outputType: OutputType): EssenceBundle {
  const selectedEssences = new Map<string, ModuleEssence>();

  function addEssence(essence: ModuleEssence): void {
    if (selectedEssences.has(essence.essenceId)) {
      return;
    }

    selectedEssences.set(essence.essenceId, essence);

    for (const dependencyId of essence.dependencies) {
      const dependency = getEssenceById(dependencyId);
      if (dependency.targetOutputs.includes(outputType)) {
        addEssence(dependency);
      }
    }
  }

  for (const essence of getEssencesByModuleIds(moduleIds, outputType)) {
    addEssence(essence);
  }

  const essences = [...selectedEssences.values()].sort((a, b) => b.priority - a.priority);

  return {
    essences,
    conflicts: detectEssenceConflicts(essences)
  };
}

export function minifyEssenceContent(essences: ModuleEssence[]): string {
  return essences.map((essence) => essence.injectableContent).join(";");
}

function detectEssenceConflicts(essences: ModuleEssence[]): EssenceConflict[] {
  const ids = new Set(essences.map((essence) => essence.essenceId));
  const conflicts: EssenceConflict[] = [];

  for (const essence of essences) {
    for (const conflictId of essence.conflicts) {
      if (ids.has(conflictId)) {
        conflicts.push({
          essenceId: essence.essenceId,
          conflictsWith: conflictId,
          reason: `${essence.essenceId} declares a conflict with ${conflictId}`
        });
      }
    }
  }

  return conflicts;
}