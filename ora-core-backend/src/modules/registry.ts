import type { OraModule } from "../types/index.js";
import { OraModuleSeedSchema } from "../schemas/module.schema.js";
import { notFound } from "../utils/errors.js";
import { readJsonSeed } from "../utils/read-json.js";

let moduleCache: OraModule[] | null = null;

export function listModuleRegistry(): OraModule[] {
  if (!moduleCache) {
    const seed = readJsonSeed<unknown>("src/modules/manifests/modules.seed.json");
    moduleCache = OraModuleSeedSchema.parse(seed);
  }

  return moduleCache;
}

export function refreshModuleRegistry(): OraModule[] {
  moduleCache = null;
  return listModuleRegistry();
}

export function getModuleById(moduleId: string): OraModule {
  const module = listModuleRegistry().find((item) => item.id === moduleId);

  if (!module) {
    throw notFound(`Module not found: ${moduleId}`);
  }

  return module;
}

export function getModulesByIds(moduleIds: string[]): OraModule[] {
  return moduleIds.map((moduleId) => getModuleById(moduleId));
}

export function resolveModuleDependencies(moduleIds: string[]): OraModule[] {
  const seen = new Set<string>();
  const dependencyIds = new Set<string>();

  function visit(moduleId: string): void {
    if (seen.has(moduleId)) {
      return;
    }

    seen.add(moduleId);
    const module = getModuleById(moduleId);

    for (const dependencyId of module.dependencies) {
      dependencyIds.add(dependencyId);
      visit(dependencyId);
    }
  }

  for (const moduleId of moduleIds) {
    visit(moduleId);
  }

  return [...dependencyIds].map((dependencyId) => getModuleById(dependencyId));
}
