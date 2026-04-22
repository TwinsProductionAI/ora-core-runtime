import type { OraModule, OraModulePack } from "../types/index.js";
import { getPackById, listPackRegistry } from "../packs/registry.js";
import { getModuleById } from "../modules/registry.js";
import { getEssenceById } from "../essences/registry.js";

export const ORA_CORE_FOUNDATION_PACK_ID = "ora-core-foundation";

export function listModulePacks(): OraModulePack[] {
  return listPackRegistry().filter((pack) => pack.status === "active" && pack.visibility === "public");
}

export function getModulePack(packId: string): OraModulePack {
  return getPackById(packId);
}

export function getCoreFoundationPack(): OraModulePack {
  return getPackById(ORA_CORE_FOUNDATION_PACK_ID);
}

export function getMandatoryBaseModuleIds(): string[] {
  const ids = new Set<string>();

  for (const pack of listPackRegistry().filter((item) => item.status === "active" && item.mandatory)) {
    for (const moduleId of pack.includedModuleIds) {
      getModuleById(moduleId);
      ids.add(moduleId);
    }

    for (const essenceId of pack.includedEssenceIds) {
      getEssenceById(essenceId);
    }
  }

  return [...ids].sort();
}

export function getMandatoryBaseModules(): OraModule[] {
  return getMandatoryBaseModuleIds().map((moduleId) => getModuleById(moduleId));
}
