import type { OraModulePack } from "../types/index.js";
import { OraModulePackSeedSchema } from "../schemas/pack.schema.js";
import { notFound } from "../utils/errors.js";
import { readJsonSeed } from "../utils/read-json.js";

let packCache: OraModulePack[] | null = null;

export function listPackRegistry(): OraModulePack[] {
  if (!packCache) {
    const seed = readJsonSeed<unknown>("src/packs/packs.seed.json");
    packCache = OraModulePackSeedSchema.parse(seed);
  }

  return packCache;
}

export function refreshPackRegistry(): OraModulePack[] {
  packCache = null;
  return listPackRegistry();
}

export function getPackById(packId: string): OraModulePack {
  const pack = listPackRegistry().find((item) => item.id === packId);

  if (!pack) {
    throw notFound(`Module pack not found: ${packId}`);
  }

  return pack;
}
