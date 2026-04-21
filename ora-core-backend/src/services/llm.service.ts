import { env } from "../config/env.js";

export interface LlmGenerateInput {
  systemPrompt: string;
  userPrompt: string;
  temperature?: number;
}

export interface LlmGenerateResult {
  provider: "stub" | "gemini";
  model?: string;
  text: string;
  isStub: boolean;
}

export async function generateWithLlm(input: LlmGenerateInput): Promise<LlmGenerateResult> {
  if (env.LLM_PROVIDER === "gemini" && env.GEMINI_API_KEY) {
    return {
      provider: "gemini",
      model: env.GEMINI_MODEL,
      text: [
        "Gemini server-side provider is configured but not executed in V1.",
        "Wire the SDK call here once product prompts and safety policy are locked.",
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
