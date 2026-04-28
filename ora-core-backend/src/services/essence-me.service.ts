import { createHash } from "node:crypto";
import type { OutputType } from "../types/index.js";
import type {
  EssenceMeAnalyzeRequest,
  EssenceMeMinimalAction,
  EssenceMeUncertaintyClass
} from "../schemas/essence-me.schema.js";
import { getEssenceById } from "../essences/registry.js";
import { getModuleById } from "../modules/registry.js";
import { resolveEssenceBundle } from "./essence.service.js";

const MODULE_ID = "essence-me-backend";
const MODULE_PUBLIC_NAME = "Essence Me Backend";
const ESSENCE_ID = "essence-me-decision-compression";
const MODULE_VERSION = "1.0.0-decision-compression";
const LOOP_TRIGGER_SCORE = 0.72;
const LOW_GAIN_THRESHOLD = 0.25;
const CONTINUATION_WARNING_SCORE = 0.55;
const FILE_SEARCH_KEYWORDS = ["fichier", "files", "repo", "code", "backend", "json", "manifest", "canon", "module", "route", "schema"];
const WEB_SEARCH_KEYWORDS = ["web", "internet", "latest", "recent", "today", "actualite", "prix", "version", "news", "regulation"];
const CONTEXT_KEYWORDS = ["contexte", "audience", "format", "perimetre", "scope", "objectif", "contrainte", "deadline", "ton", "priorite"];
const CONFLICT_KEYWORDS = ["conflict", "contradiction", "incompatible", "desaccord", "drift", "mismatch", "tension"];
const REASONING_KEYWORDS = ["reasoning", "raisonnement", "logique", "preuve", "stuck", "bloque", "blocage", "analysis", "paralysis"];
const STOP_WORDS = new Set(["alors", "avec", "avoir", "comme", "dans", "depuis", "elle", "elles", "encore", "entre", "etre", "faire", "leur", "leurs", "mais", "meme", "moins", "nous", "pour", "plus", "sans", "sera", "sont", "tres", "une", "des", "les", "que", "qui", "quoi", "dont", "this", "that", "from", "into", "cela", "same", "over", "under", "when", "then", "than", "pourquoi", "comment"]);

export interface EssenceMeCompressedState {
  goal: string;
  known: string[];
  unknown: string[];
  blocker: string[];
  risk: string[];
  minAction: string;
  stopRule: string;
  confidence: number;
}

export interface EssenceMeAssessmentTrace {
  cyclesAnalyzed: number;
  repeatedSignals: string[];
  latestDeltaSummary: string;
  loopReason: string;
  traceHash: string;
}

export interface EssenceMeAssessment {
  moduleId: string;
  publicName: string;
  version: string;
  outputType: OutputType;
  dependencies: {
    modules: string[];
    essences: string[];
  };
  loopDetected: boolean;
  loopScore: number;
  newInformationGainScore: number;
  uncertaintyClass: EssenceMeUncertaintyClass;
  minimalAction: EssenceMeMinimalAction;
  suggestedQuestion?: string;
  suggestedSearchScope?: "web" | "files";
  stopRuleTriggered: boolean;
  confidence: number;
  compressedState: EssenceMeCompressedState;
  trace: EssenceMeAssessmentTrace;
}

export const essenceMeSpec = {
  moduleId: MODULE_ID,
  publicName: MODULE_PUBLIC_NAME,
  version: MODULE_VERSION,
  role: "Detect low-gain reasoning loops, classify residual uncertainty, and choose one minimal next action.",
  activationPolicy: "Best activated when the system is repetitive, blocked, over-complex, or stuck without new signal.",
  runtimePolicy: "Deterministic backend heuristic. No new hypothesis without new data.",
  dependencyModules: ["rime", "primordia", "ecotwin"],
  primaryEssence: ESSENCE_ID
} as const;

export function analyzeEssenceMe(input: EssenceMeAnalyzeRequest): EssenceMeAssessment {
  getModuleById(MODULE_ID);
  getEssenceById(ESSENCE_ID);

  const latestCycle = input.cycles.at(-1);
  if (!latestCycle) {
    throw new Error("ESSENCE_ME_BACKEND requires at least one cycle.");
  }
  const previousCycle = input.cycles.length > 1 ? input.cycles[input.cycles.length - 2] : undefined;
  const resolvedEssenceIds = resolveEssenceBundle([MODULE_ID], input.outputType).essences.map((essence) => essence.essenceId);
  const repeatedSignals = collectRepeatedSignals(previousCycle, latestCycle);
  const repeatedSummaryScore = previousCycle ? jaccardScore(toSignalSet(previousCycle.summary), toSignalSet(latestCycle.summary)) : 0;
  const repeatedQuestionScore = previousCycle ? overlapScore(previousCycle.openQuestions, latestCycle.openQuestions) : 0;
  const repeatedHintScore = previousCycle ? overlapScore(previousCycle.uncertaintyHints, latestCycle.uncertaintyHints) : 0;
  const toolStallScore = previousCycle ? detectToolStall(previousCycle.toolsUsed, latestCycle.toolsUsed) : 0;
  const newInformationGainScore = estimateNewInformationGain(previousCycle, latestCycle);
  const loopScore = round(clamp(repeatedSummaryScore * 0.45 + repeatedQuestionScore * 0.2 + repeatedHintScore * 0.15 + toolStallScore * 0.1 + (newInformationGainScore <= LOW_GAIN_THRESHOLD ? 0.1 : 0), 0, 1));
  const stopRuleTriggered = input.cycles.length >= 2 && loopScore >= LOOP_TRIGGER_SCORE && newInformationGainScore <= LOW_GAIN_THRESHOLD;
  const uncertaintyClass = classifyUncertainty(input, latestCycle, loopScore, newInformationGainScore);
  const minimalAction = chooseMinimalAction(input, latestCycle, uncertaintyClass, stopRuleTriggered);
  const suggestedQuestion = minimalAction === "ask_one_question" ? buildClarifyingQuestion(input, latestCycle) : undefined;
  const suggestedSearchScope = minimalAction === "search_web" ? "web" : minimalAction === "search_files" ? "files" : undefined;
  const confidence = estimateDecisionConfidence(loopScore, newInformationGainScore, input.stakesLevel, minimalAction);
  const stopRule = describeStopRule(stopRuleTriggered, loopScore, newInformationGainScore, input.cycles.length);
  const known = dedupeList(input.known);
  const unknown = dedupeList(input.unknown);
  const blockers = dedupeList([...input.blockers, ...latestCycle.openQuestions]).slice(0, 6);
  const risks = dedupeList([...input.risks, ...latestCycle.uncertaintyHints]).slice(0, 6);
  const compressedState: EssenceMeCompressedState = {
    goal: normalizeSentence(input.userRequest),
    known,
    unknown,
    blocker: blockers,
    risk: risks,
    minAction: formatMinimalAction(minimalAction, suggestedQuestion),
    stopRule,
    confidence
  };

  const tracePayload = {
    moduleId: MODULE_ID,
    outputType: input.outputType,
    cyclesAnalyzed: input.cycles.length,
    repeatedSignals,
    loopScore,
    newInformationGainScore,
    uncertaintyClass,
    minimalAction,
    stakesLevel: input.stakesLevel,
    blockedBy: blockers,
    risks,
    suggestedQuestion,
    suggestedSearchScope
  };
  return {
    moduleId: MODULE_ID,
    publicName: MODULE_PUBLIC_NAME,
    version: MODULE_VERSION,
    outputType: input.outputType,
    dependencies: {
      modules: [MODULE_ID, "ecotwin", "primordia", "rime"],
      essences: resolvedEssenceIds
    },
    loopDetected: stopRuleTriggered || loopScore >= CONTINUATION_WARNING_SCORE,
    loopScore,
    newInformationGainScore,
    uncertaintyClass,
    minimalAction,
    suggestedQuestion,
    suggestedSearchScope,
    stopRuleTriggered,
    confidence,
    compressedState,
    trace: {
      cyclesAnalyzed: input.cycles.length,
      repeatedSignals,
      latestDeltaSummary: latestCycle.newInformation.length > 0 ? latestCycle.newInformation.join(" | ") : "no_new_information_detected",
      loopReason: buildLoopReason(loopScore, newInformationGainScore, repeatedSignals),
      traceHash: `sha256:${sha256(stableStringify(tracePayload))}`
    }
  };
}

function collectRepeatedSignals(previousCycle: EssenceMeAnalyzeRequest["cycles"][number] | undefined, latestCycle: EssenceMeAnalyzeRequest["cycles"][number]): string[] {
  if (!previousCycle) {
    return [];
  }

  const repeatedSummaryTokens = intersect([...toSignalSet(previousCycle.summary)], [...toSignalSet(latestCycle.summary)]).slice(0, 5).map((token) => `summary:${token}`);
  const repeatedQuestions = intersect(previousCycle.openQuestions, latestCycle.openQuestions).slice(0, 3).map((item) => `question:${normalizeSentence(item)}`);
  const repeatedHints = intersect(previousCycle.uncertaintyHints, latestCycle.uncertaintyHints).slice(0, 3).map((item) => `hint:${normalizeSentence(item)}`);
  const repeatedTools = detectToolStall(previousCycle.toolsUsed, latestCycle.toolsUsed) > 0.8 ? ["tools:reused_without_gain"] : [];

  return dedupeList([...repeatedSummaryTokens, ...repeatedQuestions, ...repeatedHints, ...repeatedTools]).slice(0, 12);
}

function classifyUncertainty(input: EssenceMeAnalyzeRequest, latestCycle: EssenceMeAnalyzeRequest["cycles"][number], loopScore: number, newInformationGainScore: number): EssenceMeUncertaintyClass {
  const evidence = [input.userRequest, ...input.unknown, ...input.blockers, ...input.risks, ...latestCycle.openQuestions, ...latestCycle.uncertaintyHints].join(" ");

  if (containsKeyword(evidence, CONFLICT_KEYWORDS)) {
    return "conflict";
  }

  if (containsKeyword(evidence, REASONING_KEYWORDS) && input.blockers.length > 0) {
    return "reasoning_block";
  }

  if (input.cycles.length >= 4 || input.unknown.length + input.blockers.length + latestCycle.openQuestions.length >= 6) {
    return "overcomplexity";
  }

  if (containsKeyword(evidence, CONTEXT_KEYWORDS)) {
    return "context_missing";
  }

  if (input.unknown.length > 0 || (newInformationGainScore <= LOW_GAIN_THRESHOLD && input.allowSearchFiles)) {
    return "data_missing";
  }

  if (loopScore >= CONTINUATION_WARNING_SCORE || newInformationGainScore <= LOW_GAIN_THRESHOLD) {
    return "low_value_continuation";
  }

  return "low_value_continuation";
}

function chooseMinimalAction(input: EssenceMeAnalyzeRequest, latestCycle: EssenceMeAnalyzeRequest["cycles"][number], uncertaintyClass: EssenceMeUncertaintyClass, stopRuleTriggered: boolean): EssenceMeMinimalAction {
  const evidence = [input.userRequest, ...input.unknown, ...input.blockers, ...latestCycle.openQuestions].join(" ");
  const prefersFileSearch = containsKeyword(evidence, FILE_SEARCH_KEYWORDS);
  const prefersWebSearch = containsKeyword(evidence, WEB_SEARCH_KEYWORDS);

  if (input.stakesLevel === "high") {
    if (uncertaintyClass === "conflict") {
      if (prefersFileSearch && input.allowSearchFiles) {
        return "search_files";
      }
      if (input.allowSearchWeb) {
        return "search_web";
      }
      return "produce_partial";
    }

    if (uncertaintyClass === "data_missing") {
      if (prefersFileSearch && input.allowSearchFiles) {
        return "search_files";
      }
      if (prefersWebSearch && input.allowSearchWeb) {
        return "search_web";
      }
      return input.allowSearchFiles ? "search_files" : input.allowSearchWeb ? "search_web" : "ask_one_question";
    }

    if (uncertaintyClass === "reasoning_block") {
      return "produce_partial";
    }
  }

  switch (uncertaintyClass) {
    case "conflict":
      if (prefersFileSearch && input.allowSearchFiles) {
        return "search_files";
      }
      if (input.allowSearchWeb) {
        return "search_web";
      }
      return "produce_partial";
    case "data_missing":
      if (prefersFileSearch && input.allowSearchFiles) {
        return "search_files";
      }
      if (prefersWebSearch && input.allowSearchWeb) {
        return "search_web";
      }
      if (input.allowSearchFiles) {
        return "search_files";
      }
      if (input.allowSearchWeb) {
        return "search_web";
      }
      return "ask_one_question";
    case "context_missing":
      return "ask_one_question";
    case "reasoning_block":
      return "simplify_scope";
    case "overcomplexity":
      return "simplify_scope";
    case "low_value_continuation":
      if (stopRuleTriggered && input.known.length === 0) {
        return "stop_clean";
      }
      return input.known.length > 0 ? "answer_now" : "produce_partial";
    default:
      return "produce_partial";
  }
}
function buildClarifyingQuestion(input: EssenceMeAnalyzeRequest, latestCycle: EssenceMeAnalyzeRequest["cycles"][number]): string {
  const primaryUnknown = input.unknown[0] ?? latestCycle.openQuestions[0];

  if (primaryUnknown) {
    return `Quelle information unique manque le plus pour lever: ${normalizeSentence(primaryUnknown)} ?`;
  }

  return "Quelle contrainte unique dois-je verrouiller pour avancer sans tourner en rond ?";
}

function estimateNewInformationGain(previousCycle: EssenceMeAnalyzeRequest["cycles"][number] | undefined, latestCycle: EssenceMeAnalyzeRequest["cycles"][number]): number {
  const previousInfo = new Set((previousCycle?.newInformation ?? []).map((item) => normalizeSentence(item)));
  const previousTools = new Set((previousCycle?.toolsUsed ?? []).map((item) => normalizeSentence(item)));
  const latestInfoDelta = latestCycle.newInformation.filter((item) => !previousInfo.has(normalizeSentence(item))).length;
  const latestToolDelta = latestCycle.toolsUsed.filter((item) => !previousTools.has(normalizeSentence(item))).length;
  const openQuestionRelief = previousCycle ? Math.max(0, previousCycle.openQuestions.length - latestCycle.openQuestions.length) : 0;

  return round(clamp((latestInfoDelta * 0.6 + latestToolDelta * 0.2 + openQuestionRelief * 0.2) / 3, 0, 1));
}

function estimateDecisionConfidence(loopScore: number, newInformationGainScore: number, stakesLevel: EssenceMeAnalyzeRequest["stakesLevel"], minimalAction: EssenceMeMinimalAction): number {
  const stakesPenalty = stakesLevel === "high" ? 0.08 : stakesLevel === "medium" ? 0.04 : 0;
  const actionBonus = minimalAction === "answer_now" || minimalAction === "stop_clean" ? 0.02 : 0.07;
  return round(clamp(0.48 + loopScore * 0.28 + (1 - newInformationGainScore) * 0.18 + actionBonus - stakesPenalty, 0.25, 0.95));
}

function buildLoopReason(loopScore: number, newInformationGainScore: number, repeatedSignals: string[]): string {
  if (repeatedSignals.length === 0) {
    return `low_repeat_signal(loop=${loopScore},gain=${newInformationGainScore})`;
  }

  return `repeat_detected(loop=${loopScore},gain=${newInformationGainScore},signals=${repeatedSignals.slice(0, 4).join("|")})`;
}

function describeStopRule(stopRuleTriggered: boolean, loopScore: number, newInformationGainScore: number, cycles: number): string {
  if (stopRuleTriggered) {
    return `repeat_after_${cycles}_cycles_without_gain(loop=${loopScore},gain=${newInformationGainScore})`;
  }

  if (loopScore >= CONTINUATION_WARNING_SCORE) {
    return `continuation_warning(loop=${loopScore},gain=${newInformationGainScore})`;
  }

  return `no_stop_rule(loop=${loopScore},gain=${newInformationGainScore})`;
}

function formatMinimalAction(action: EssenceMeMinimalAction, question?: string): string {
  if (action === "ask_one_question" && question) {
    return `${action.toUpperCase()}: ${question}`;
  }

  return action.toUpperCase();
}

function detectToolStall(previousTools: string[], latestTools: string[]): number {
  if (previousTools.length === 0 || latestTools.length === 0) {
    return 0;
  }

  return overlapScore(previousTools, latestTools) >= 0.8 ? 1 : 0;
}

function overlapScore(left: string[], right: string[]): number {
  const leftSet = new Set(left.map((item) => normalizeSentence(item)));
  const rightSet = new Set(right.map((item) => normalizeSentence(item)));

  if (leftSet.size === 0 || rightSet.size === 0) {
    return 0;
  }

  return round(intersect([...leftSet], [...rightSet]).length / Math.max(leftSet.size, rightSet.size));
}

function jaccardScore(left: Set<string>, right: Set<string>): number {
  if (left.size === 0 || right.size === 0) {
    return 0;
  }

  const intersection = intersect([...left], [...right]).length;
  const union = new Set([...left, ...right]).size;
  return round(intersection / union);
}

function toSignalSet(text: string): Set<string> {
  return new Set((text.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? []).map((token) => token.trim()).filter((token) => token.length >= 4 && !STOP_WORDS.has(token)));
}

function containsKeyword(text: string, keywords: string[]): boolean {
  const haystack = normalizeSentence(text);
  return keywords.some((keyword) => haystack.includes(keyword.toLowerCase()));
}

function normalizeSentence(text: string): string {
  return text.replace(/\s+/g, " ").trim().toLowerCase();
}

function dedupeList(values: string[]): string[] {
  const seen = new Set<string>();
  const result: string[] = [];

  for (const value of values) {
    const normalized = normalizeSentence(value);
    if (!normalized || seen.has(normalized)) {
      continue;
    }
    seen.add(normalized);
    result.push(value.trim());
  }

  return result;
}

function intersect(left: string[], right: string[]): string[] {
  const rightSet = new Set(right.map((item) => normalizeSentence(item)));
  return dedupeList(left).filter((item) => rightSet.has(normalizeSentence(item)));
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function round(value: number): number {
  return Math.round(value * 10000) / 10000;
}

function sha256(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function stableStringify(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }

  if (value && typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>).filter(([, entryValue]) => entryValue !== undefined).sort(([left], [right]) => left.localeCompare(right));
    return `{${entries.map(([key, entryValue]) => `${JSON.stringify(key)}:${stableStringify(entryValue)}`).join(",")}}`;
  }

  return JSON.stringify(value);
}
