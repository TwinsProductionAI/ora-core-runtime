import "dotenv/config";
import { z } from "zod";

const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3333),
  CORS_ORIGIN: z.string().default("*"),
  GITHUB_ORG_URL: z.string().url().default("https://github.com/TwinsProductionAI"),
  GITHUB_TOKEN: z.string().optional(),
  LLM_PROVIDER: z.enum(["stub", "external"]).default("stub"),
  LLM_API_KEY: z.string().optional(),
  LLM_MODEL: z.string().optional()
});

export const env = EnvSchema.parse(process.env);