import type { OutputType, TokenEstimate } from "../types/index.js";
import type { EstimateTokensRequest } from "../schemas/request.schema.js";
import { getActivatedModuleIds } from "./capability.service.js";
import { resolveModuleDependencies } from "../modules/registry.js";
import { resolveEssenceBundle } from "./essence.service.js";

const outputScaffoldTokens: Record<OutputType, number> = {
  direct: 380,
  md: 550,
  master: 260
};

const outputMultipliers: Record<OutputType, number> = {
  direct: 1,
  md: 1.35,
  master: 0.85
};

export function estimateTextTokens(text: string): number {
  const trimmed = text.trim();
  if (!trimmed) {
    return 0;
  }

  return Math.max(1, Math.ceil(trimmed.length / 4));
}

export function estimateTokenCost(input: EstimateTokensRequest): TokenEstimate {
  const activatedModuleIds = new Set<string>([
    ...input.selectedModuleIds,
    ...getActivatedModuleIds(input.selectedCapabilityIds)
  ]);

  for (const dependency of resolveModuleDependencies([...activatedModuleIds])) {
    activatedModuleIds.add(dependency.id);
  }

  const essenceBundle = resolveEssenceBundle([...activatedModuleIds], input.outputType);
  const userRequestTokens = estimateTextTokens(input.userRequest);
  const moduleWeightTokens = Math.round(
    essenceBundle.essences.reduce((total, essence) => total + essence.tokenWeight, 0) * 120
  );
  const scaffoldTokens = outputScaffoldTokens[input.outputType];
  const outputMultiplier = outputMultipliers[input.outputType];
  const tokEst = Math.ceil((userRequestTokens + moduleWeightTokens + scaffoldTokens) * outputMultiplier);

  return {
    tokEst,
    method:
      "V1 heuristic: ceil((chars/4 + resolved essence token weights*120 + output scaffold) * output multiplier). Not an exact tokenizer.",
    breakdown: {
      userRequestTokens,
      moduleWeightTokens,
      outputScaffoldTokens: scaffoldTokens,
      outputMultiplier
    }
  };
}