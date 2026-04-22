import type {
  BlockedModule,
  Capability,
  NeedAnalysis,
  OraModule,
  SelectionConflict,
  SelectionResult
} from "../types/index.js";
import type { AnalyzeNeedRequest, SelectionResolveRequest } from "../schemas/request.schema.js";
import { getCapabilities, listCapabilities } from "./capability.service.js";
import { getModuleById, getModulesByIds, resolveModuleDependencies } from "../modules/registry.js";
import { canUseModule, getPlan } from "./plan.service.js";
import { resolveEssenceBundle } from "./essence.service.js";

const keywordCapabilityMap: Array<{ keywords: string[]; capabilityId: string }> = [
  { keywords: ["fiable", "fiabilite", "verifie", "verifier", "truth", "risque"], capabilityId: "reliability" },
  { keywords: ["ambigu", "ambiguite", "clarifie", "structure", "contrainte"], capabilityId: "ambiguity-reduction" },
  { keywords: ["creatif", "idee", "concept", "story", "narration", "prompt"], capabilityId: "guided-creativity" },
  { keywords: ["markdown", ".md", "export", "projet", "download"], capabilityId: "project-export" },
  { keywords: ["consultant", "strategie", "decision", "risque", "business"], capabilityId: "consultant-mode" },
  { keywords: ["pme", "vente", "commercial", "client", "roi"], capabilityId: "sme-mode" },
  { keywords: ["gouvernance", "veto", "securite", "canon"], capabilityId: "strong-governance" },
  { keywords: ["image", "manga", "storyboard", "video", "visuel"], capabilityId: "visual-pipeline" }
];

export function analyzeNeed(input: AnalyzeNeedRequest): {
  needAnalysis: NeedAnalysis;
  recommendedCapabilities: Capability[];
} {
  const normalized = input.userRequest.toLowerCase();
  const detectedKeywords = new Set<string>();
  const capabilityIds = new Set<string>(["reliability"]);

  for (const mapping of keywordCapabilityMap) {
    for (const keyword of mapping.keywords) {
      if (normalized.includes(keyword)) {
        detectedKeywords.add(keyword);
        capabilityIds.add(mapping.capabilityId);
      }
    }
  }

  const outputHint = normalized.includes(".md") || normalized.includes("markdown") || normalized.includes("export")
    ? "md"
    : normalized.includes("preference") || normalized.includes("master")
      ? "master"
      : "direct";

  const intentClass =
    outputHint === "md"
      ? "project_export"
      : outputHint === "master"
        ? "preference_master"
        : normalized.includes("consultant") || normalized.includes("strategie")
          ? "consulting"
          : normalized.includes("prompt")
            ? "prompt"
            : "general";

  const riskLevel = normalized.includes("legal") || normalized.includes("medical") || normalized.includes("finance")
    ? "high"
    : normalized.includes("client") || normalized.includes("business")
      ? "medium"
      : "low";

  const recommendedCapabilities = getCapabilities([...capabilityIds]).filter((capability) => capability.status === "active");

  return {
    needAnalysis: {
      summary: "Analyse heuristique V1 basee sur mots-cles. A remplacer plus tard par service LLM serveur si besoin.",
      detectedKeywords: [...detectedKeywords],
      intentClass,
      riskLevel,
      outputHint
    },
    recommendedCapabilities
  };
}

export function resolveSelection(input: SelectionResolveRequest): SelectionResult {
  const plan = getPlan(input.planId);
  const analysis = analyzeNeed({ userRequest: input.userRequest, clientContext: input.clientContext });
  const targetOutput = input.clientContext?.preferredOutput ?? analysis.needAnalysis.outputHint;
  const selectedCapabilityIds =
    input.selectedCapabilityIds.length > 0
      ? input.selectedCapabilityIds
      : analysis.recommendedCapabilities.map((capability) => capability.id);

  const visibleCapabilityIds = new Set(listCapabilities(input.planId).map((capability) => capability.id));
  const selectedCapabilities = getCapabilities(selectedCapabilityIds).filter((capability) =>
    visibleCapabilityIds.has(capability.id) && capability.compatibleOutputs.includes(targetOutput)
  );

  const baseModuleIds = new Set<string>(input.selectedModuleIds);
  for (const capability of selectedCapabilities) {
    for (const moduleId of capability.mappedModules) {
      baseModuleIds.add(moduleId);
    }
  }

  const dependencyModules = resolveModuleDependencies([...baseModuleIds]);
  const selectedModuleIds = new Set<string>(baseModuleIds);
  for (const dependency of dependencyModules) {
    selectedModuleIds.add(dependency.id);
  }

  const requestedModules = getModulesByIds([...selectedModuleIds]);
  const conflicts = detectConflicts(requestedModules);
  const authorizedModules = requestedModules.filter((module) => canUseModule(input.planId, module));
  const blockedByPlan = requestedModules
    .filter((module) => !canUseModule(input.planId, module))
    .map<BlockedModule>((module) => ({
      moduleId: module.id,
      publicName: module.publicName,
      requiredTier: module.tier,
      currentPlan: input.planId,
      upgradeHint: plan.upgradeHint ?? "Upgrade required for this module."
    }));
  const autoAddedDependencies = dependencyModules.filter((module) => !baseModuleIds.has(module.id));
  const essenceBundle = resolveEssenceBundle(
    authorizedModules.map((module) => module.id),
    targetOutput
  );

  return {
    planId: input.planId,
    needAnalysis: analysis.needAnalysis,
    recommendedCapabilities: analysis.recommendedCapabilities,
    selectedCapabilities,
    recommendedModules: authorizedModules,
    authorizedModules,
    blockedByPlan,
    requiredDependencies: dependencyModules,
    autoAddedDependencies,
    resolvedEssences: essenceBundle.essences,
    essenceConflicts: essenceBundle.conflicts,
    conflicts
  };
}

function detectConflicts(modules: OraModule[]): SelectionConflict[] {
  const moduleIds = new Set(modules.map((module) => module.id));
  const conflicts: SelectionConflict[] = [];

  for (const module of modules) {
    for (const conflictId of module.conflicts) {
      if (moduleIds.has(conflictId)) {
        conflicts.push({
          moduleId: module.id,
          conflictsWith: conflictId,
          reason: `${module.id} cannot be enabled together with ${conflictId}`
        });
      }
    }
  }

  return conflicts;
}

export function getModuleSelectionPreview(moduleIds: string[]): OraModule[] {
  return moduleIds.map((moduleId) => getModuleById(moduleId));
}