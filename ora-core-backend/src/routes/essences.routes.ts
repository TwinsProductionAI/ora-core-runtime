import { Router } from "express";
import { OutputTypeSchema } from "../schemas/common.schema.js";
import { getEssenceById } from "../essences/registry.js";
import { listEssences, resolveEssenceBundle } from "../services/essence.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { badRequest } from "../utils/errors.js";
import { ok } from "../utils/http.js";

export const essencesRouter = Router();

essencesRouter.get(
  "/essences",
  asyncHandler((req, res) => {
    const outputParse = OutputTypeSchema.optional().safeParse(req.query.outputType);
    const outputType = outputParse.success ? outputParse.data : undefined;

    return ok(res, listEssences(outputType));
  })
);

essencesRouter.get(
  "/essences/resolve/by-modules",
  asyncHandler((req, res) => {
    const ids = typeof req.query.moduleIds === "string" ? req.query.moduleIds.split(",").filter(Boolean) : [];
    const outputParse = OutputTypeSchema.safeParse(req.query.outputType);
    const outputType = outputParse.success ? outputParse.data : "direct";

    return ok(res, resolveEssenceBundle(ids, outputType));
  })
);

essencesRouter.get(
  "/essences/:id",
  asyncHandler((req, res) => {
    const essenceId = req.params.id;
    if (!essenceId) {
      throw badRequest("Missing essence id.");
    }

    return ok(res, getEssenceById(essenceId));
  })
);
