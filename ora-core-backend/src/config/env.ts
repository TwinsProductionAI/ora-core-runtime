import "dotenv/config";
import { z } from "zod";

const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3333),
  CORS_ORIGIN: z.string().default("*"),
  GITHUB_ORG_URL: z.string().url().default("https://github.com/TwinsProductionAI"),
  GITHUB_TOKEN: z.string().optional(),
  LLM_PROVIDER: z.enum(["stub", "gemini"]).default("stub"),
  GEMINI_API_KEY: z.string().optional(),
  GEMINI_MODEL: z.string().default("gemini-1.5-flash")
});

export const env = EnvSchema.parse(process.env);
