import type { Capability } from "../types/index.js";
import { CapabilitySeedSchema } from "../schemas/capability.schema.js";
import { notFound } from "../utils/errors.js";
import { readJsonSeed } from "../utils/read-json.js";

let capabilityCache: Capability[] | null = null;

export function listCapabilityRegistry(): Capability[] {
  if (!capabilityCache) {
    const seed = readJsonSeed<unknown>("src/capabilities/capabilities.seed.json");
    capabilityCache = CapabilitySeedSchema.parse(seed);
  }

  return capabilityCache;
}

export function getCapabilityById(capabilityId: string): Capability {
  const capability = listCapabilityRegistry().find((item) => item.id === capabilityId);

  if (!capability) {
    throw notFound(`Capability not found: ${capabilityId}`);
  }

  return capability;
}

export function getCapabilitiesByIds(capabilityIds: string[]): Capability[] {
  return capabilityIds.map((capabilityId) => getCapabilityById(capabilityId));
}
