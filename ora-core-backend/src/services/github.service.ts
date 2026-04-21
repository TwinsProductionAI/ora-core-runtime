import type { RepoInfo } from "../types/index.js";
import { env } from "../config/env.js";
import { getModuleById, listModuleRegistry, refreshModuleRegistry } from "../modules/registry.js";

export function listRepos(): RepoInfo[] {
  return listModuleRegistry().map((module) => ({
    moduleId: module.id,
    publicName: module.publicName,
    internalName: module.internalName,
    repoUrl: module.repoUrl || env.GITHUB_ORG_URL,
    sourceMode: "local-mock",
    isVerified: module.validationState === "validated"
  }));
}

export function getModuleManifest(moduleId: string) {
  return getModuleById(moduleId);
}

export function getModuleSourceInfo(moduleId: string): RepoInfo {
  const module = getModuleById(moduleId);

  return {
    moduleId: module.id,
    publicName: module.publicName,
    internalName: module.internalName,
    repoUrl: module.repoUrl || env.GITHUB_ORG_URL,
    sourceMode: "local-mock",
    isVerified: module.validationState === "validated"
  };
}

export function refreshRegistryFromGithub() {
  const registry = refreshModuleRegistry();

  return {
    refreshed: false,
    mode: "stub",
    source: "local seeds",
    message: "GitHub remote refresh is prepared but not active in V1.",
    moduleCount: registry.length
  };
}
