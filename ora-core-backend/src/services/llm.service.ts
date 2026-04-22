import { env } from "../config/env.js";

export interface LlmGenerateInput {
  systemPrompt: string;
  userPrompt: string;
  temperature?: number;
}

export interface LlmGenerateResult {
  provider: "stub" | "external";
  model?: string;
  text: string;
  isStub: boolean;
}

export async function generateWithLlm(input: LlmGenerateInput): Promise<LlmGenerateResult> {
  if (env.LLM_PROVIDER === "external") {
    return {
      provider: "external",
      model: env.LLM_MODEL,
      text: [
        "EXTERNAL_LLM_STUB_RESPONSE",
        "No external model call was made in V1.",
        "Wire a server-side provider here only after product prompts, safety policy and billing are locked.",
        `User prompt preview: ${input.userPrompt.slice(0, 240)}`
      ].join("\n"),
      isStub: true
    };
  }

  return {
    provider: "stub",
    text: [
      "LLM_STUB_RESPONSE",
      "No external model call was made.",
      `User prompt preview: ${input.userPrompt.slice(0, 240)}`
    ].join("\n"),
    isStub: true
  };
}