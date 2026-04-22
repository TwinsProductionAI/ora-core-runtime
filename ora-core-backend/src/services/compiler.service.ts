import type { CompileResult, OutputType } from "../types/index.js";
import type { CompileRequest, SelectionResolveRequest } from "../schemas/request.schema.js";
import { canUseOutput } from "./plan.service.js";
import { resolveSelection } from "./orchestrator.service.js";
import { estimateTokenCost } from "./token-estimator.service.js";
import { minifyEssenceContent } from "./essence.service.js";
import { badRequest } from "../utils/errors.js";

export function compileDirectPrompt(input: CompileRequest): CompileResult {
  return compileOutput(input, "direct");
}

export function compileProjectMd(input: CompileRequest): CompileResult {
  return compileOutput(input, "md");
}

export function compileMaster(input: CompileRequest): CompileResult {
  return compileOutput(input, "master");
}

function compileOutput(input: CompileRequest, outputType: OutputType): CompileResult {
  if (!canUseOutput(input.planId, outputType)) {
    throw badRequest(`Output '${outputType}' is not allowed for plan '${input.planId}'.`);
  }

  const selectionInput: SelectionResolveRequest = {
    userRequest: input.userRequest,
    planId: input.planId,
    selectedCapabilityIds: input.selectedCapabilityIds,
    selectedModuleIds: input.selectedModuleIds,
    clientContext: { ...input.clientContext, preferredOutput: outputType }
  };
  const selection = resolveSelection(selectionInput);
  const selectedModuleIds = selection.authorizedModules.map((module) => module.id);
  const tokenEstimate = estimateTokenCost({
    userRequest: input.userRequest,
    outputType,
    selectedCapabilityIds: selection.selectedCapabilities.map((capability) => capability.id),
    selectedModuleIds
  });

  const content =
    outputType === "direct"
      ? renderDirectPrompt(input, tokenEstimate.tokEst, selection)
      : outputType === "md"
        ? renderProjectMd(input, tokenEstimate.tokEst, selection)
        : renderMaster(input, tokenEstimate.tokEst, selection);

  return {
    outputType,
    content,
    tokenEstimate,
    selection,
    essences: selection.resolvedEssences
  };
}

function renderDirectPrompt(input: CompileRequest, tokEst: number, selection: ReturnType<typeof resolveSelection>): string {
  const capabilityLines = selection.selectedCapabilities.map((capability) => `- ${capability.label}`).join("\n");
  const moduleMetadataLines = selection.authorizedModules.map((module) => `- ${module.publicName} (${module.id})`).join("\n");
  const essenceLines = selection.resolvedEssences
    .map((essence) => `- ${essence.essenceId}: ${essence.injectableContent}`)
    .join("\n");

  return [
    "# ORA Direct Prompt",
    `TOK_EST≈${tokEst}`,
    `PLAN: ${selection.planId}`,
    "SOURCE: ora-core-backend/v1 local mock",
    "",
    "## Demande utilisateur",
    input.userRequest,
    "",
    "## Capacites activees",
    capabilityLines || "- Fiabilite de base",
    "",
    "## Modules autorises (metadata only)",
    moduleMetadataLines || "- Aucun module autorise par le plan actuel",
    "",
    "## Essences operationnelles injectees",
    essenceLines || "- Aucune essence resolue",
    "",
    "## Grenaprompt lisible",
    `INTENT: ${selection.needAnalysis.intentClass}`,
    `RISK: ${selection.needAnalysis.riskLevel}`,
    "RULES: verite avant confort; marquer les incertitudes; ne pas inventer de source; rester exploitable.",
    "",
    "## GPV2_MIN",
    `GPV2|v=1|out=direct|plan=${selection.planId}|tok_est=${tokEst}|caps=[${selection.selectedCapabilities
      .map((capability) => capability.id)
      .join(",")}]|ess=[${selection.resolvedEssences.map((essence) => essence.essenceId).join(",")}]|mods=[${selection.authorizedModules
      .map((module) => module.id)
      .join(",")}]`
  ].join("\n");
}

function renderProjectMd(input: CompileRequest, tokEst: number, selection: ReturnType<typeof resolveSelection>): string {
  const title = input.title ?? "ORA Project Configuration";
  const modules = selection.authorizedModules.map((module) => `- **${module.publicName}** (${module.id})`).join("\n");
  const essences = selection.resolvedEssences
    .map((essence) => `- **${essence.essenceId}** [${essence.essenceType}]: \`${essence.injectableContent}\``)
    .join("\n");
  const blocked = selection.blockedByPlan
    .map((module) => `- ${module.publicName}: requires ${module.requiredTier}`)
    .join("\n");

  return [
    `# ${title}`,
    "",
    `TOK_EST≈${tokEst}`,
    `PLAN: ${selection.planId}`,
    "",
    "## User request",
    input.userRequest,
    "",
    "## Need analysis",
    `- Intent: ${selection.needAnalysis.intentClass}`,
    `- Risk: ${selection.needAnalysis.riskLevel}`,
    `- Output hint: ${selection.needAnalysis.outputHint}`,
    "",
    "## Active capabilities",
    selection.selectedCapabilities.map((capability) => `- ${capability.label}`).join("\n") || "- None",
    "",
    "## Authorized modules",
    modules || "- None",
    "",
    "## Operational essences",
    essences || "- None",
    "",
    "## Blocked by plan",
    blocked || "- None",
    "",
    "## Operating rules",
    "- Compile module essences, not raw module blocks.",
    "- Keep frontend as UI layer only.",
    "- Centralize business logic and optional LLM calls in backend.",
    "- Mark uncertain facts instead of inventing.",
    "- Keep generated artifacts downloadable by the frontend."
  ].join("\n");
}

function renderMaster(input: CompileRequest, tokEst: number, selection: ReturnType<typeof resolveSelection>): string {
  const caps = selection.selectedCapabilities.map((capability) => capability.id).join(",");
  const ess = selection.resolvedEssences.map((essence) => essence.essenceId).join(",");
  const core = minifyEssenceContent(selection.resolvedEssences);

  return [
    "ORA_MASTER_PREF_V1",
    `TOK_EST≈${tokEst}`,
    `PLAN=${selection.planId}`,
    `INTENT=${selection.needAnalysis.intentClass}`,
    `RISK=${selection.needAnalysis.riskLevel}`,
    `CAPS=[${caps}]`,
    `ESS=[${ess}]`,
    `CORE=[${core}]`,
    "RULES=[truth_over_comfort,no_fake_sources,uncertainty_marking,frontend_ui_only,compile_essences_not_raw_modules]",
    `REQUEST=${input.userRequest.replace(/\s+/g, " ").trim()}`
  ].join("|");
}