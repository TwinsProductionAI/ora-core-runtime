import type { ModuleEssence, OutputType } from "../types/index.js";
import { ModuleEssenceSeedSchema } from "../schemas/essence.schema.js";
import { notFound } from "../utils/errors.js";
import { readJsonSeed } from "../utils/read-json.js";

let essenceCache: ModuleEssence[] | null = null;

export function listEssenceRegistry(): ModuleEssence[] {
  if (!essenceCache) {
    const seed = readJsonSeed<unknown>("src/essences/essences.seed.json");
    essenceCache = ModuleEssenceSeedSchema.parse(seed);
  }

  return essenceCache;
}

export function refreshEssenceRegistry(): ModuleEssence[] {
  essenceCache = null;
  return listEssenceRegistry();
}

export function getEssenceById(essenceId: string): ModuleEssence {
  const essence = listEssenceRegistry().find((item) => item.essenceId === essenceId);

  if (!essence) {
    throw notFound(`Essence not found: ${essenceId}`);
  }

  return essence;
}

export function getEssencesByModuleIds(moduleIds: string[], outputType?: OutputType): ModuleEssence[] {
  const moduleIdSet = new Set(moduleIds);

  return listEssenceRegistry().filter((essence) =>
    moduleIdSet.has(essence.moduleId) && (outputType ? essence.targetOutputs.includes(outputType) : true)
  );
}