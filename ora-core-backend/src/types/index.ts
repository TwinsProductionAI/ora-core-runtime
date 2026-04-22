export const moduleTierValues = ["free", "standard", "pro", "enterprise"] as const;
export type ModuleTier = (typeof moduleTierValues)[number];

export const planTierValues = ["free", "creator", "pro", "enterprise"] as const;
export type PlanTier = (typeof planTierValues)[number];

export const outputTypeValues = ["direct", "md", "master"] as const;
export type OutputType = (typeof outputTypeValues)[number];

export const moduleStatusValues = ["alpha", "beta", "stable", "deprecated"] as const;
export type ModuleStatus = (typeof moduleStatusValues)[number];

export const validationStateValues = ["mocked", "draft", "validated", "blocked"] as const;
export type ValidationState = (typeof validationStateValues)[number];

export const essenceTypeValues = [
  "governance",
  "clarity",
  "compression",
  "formatting",
  "reasoning_frame",
  "style_control",
  "safety_frame",
  "traceability",
  "project_context",
  "persistent_preferences"
] as const;
export type EssenceType = (typeof essenceTypeValues)[number];

export interface OraModule {
  id: string;
  publicName: string;
  internalName: string;
  description: string;
  fullDescription: string;
  repoUrl: string;
  category: string;
  tier: ModuleTier;
  compatibleOutputs: OutputType[];
  dependencies: string[];
  conflicts: string[];
  tokenCostWeight: number;
  codeTemplate?: string;
  tags: string[];
  status: ModuleStatus;
  validationState: ValidationState;
}

export interface ModuleEssence {
  essenceId: string;
  moduleId: string;
  essenceType: EssenceType;
  targetOutputs: OutputType[];
  priority: number;
  compressionLevel: number;
  injectableContent: string;
  dependencies: string[];
  conflicts: string[];
  tokenWeight: number;
}

export interface Capability {
  id: string;
  label: string;
  description: string;
  mappedModules: string[];
  requiredPlan: PlanTier;
  compatibleOutputs: OutputType[];
  tags: string[];
  status: "active" | "hidden" | "deprecated";
}

export interface PlanDefinition {
  id: PlanTier;
  publicName: string;
  description: string;
  includedModuleTiers: ModuleTier[];
  allowedOutputs: OutputType[];
  visibleCapabilityIds: string[] | "all";
  maxTokenEstimate: number;
  upgradeHint?: string;
}

export interface ClientContext {
  audience?: string;
  projectType?: string;
  constraints?: string[];
  selectedCapabilityIds?: string[];
  preferredOutput?: OutputType;
}

export interface NeedAnalysis {
  summary: string;
  detectedKeywords: string[];
  intentClass: "prompt" | "project_export" | "preference_master" | "consulting" | "general";
  riskLevel: "low" | "medium" | "high";
  outputHint: OutputType;
}

export interface SelectionConflict {
  moduleId: string;
  conflictsWith: string;
  reason: string;
}

export interface EssenceConflict {
  essenceId: string;
  conflictsWith: string;
  reason: string;
}

export interface EssenceBundle {
  essences: ModuleEssence[];
  conflicts: EssenceConflict[];
}

export interface BlockedModule {
  moduleId: string;
  publicName: string;
  requiredTier: ModuleTier;
  currentPlan: PlanTier;
  upgradeHint: string;
}

export interface SelectionResult {
  planId: PlanTier;
  needAnalysis: NeedAnalysis;
  recommendedCapabilities: Capability[];
  selectedCapabilities: Capability[];
  recommendedModules: OraModule[];
  authorizedModules: OraModule[];
  blockedByPlan: BlockedModule[];
  requiredDependencies: OraModule[];
  autoAddedDependencies: OraModule[];
  resolvedEssences: ModuleEssence[];
  essenceConflicts: EssenceConflict[];
  conflicts: SelectionConflict[];
}

export interface TokenEstimate {
  tokEst: number;
  method: string;
  breakdown: {
    userRequestTokens: number;
    moduleWeightTokens: number;
    outputScaffoldTokens: number;
    outputMultiplier: number;
  };
}

export interface CompileResult {
  outputType: OutputType;
  content: string;
  tokenEstimate: TokenEstimate;
  selection: SelectionResult;
  essences: ModuleEssence[];
}

export interface RepoInfo {
  moduleId: string;
  publicName: string;
  internalName: string;
  repoUrl: string;
  sourceMode: "local-mock" | "github";
  isVerified: boolean;
}
export type HaloDecision = "ALLOW" | "MODIFY" | "REQUEST_EVIDENCE" | "BLOCK" | "TRACE_ONLY";
export type HaloDecisionOwner = "PRIMORDIA" | "RIME" | "ECO_TWIN" | "HALO_TRACECORE";

export interface HaloAuditMetrics {
  tokensEst?: number;
  energyWhEst?: number;
  co2eqGEst?: number;
  latencyMsMeasured?: number;
  measured: boolean;
}

export interface HaloAuditEvent {
  eventId: string;
  timestamp: string;
  sessionRef: string;
  inputRef: string;
  essencesActive: string[];
  modulesActive: string[];
  governanceTrigger: string;
  decision: HaloDecision;
  decisionOwner: HaloDecisionOwner;
  reasonShort: string;
  uncertaintyFlags: string[];
  metrics: HaloAuditMetrics;
  traceHash: string;
}
