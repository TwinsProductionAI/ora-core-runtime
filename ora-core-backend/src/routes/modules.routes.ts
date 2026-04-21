import { Router } from "express";
import { getModuleById, listModuleRegistry } from "../modules/registry.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const modulesRouter = Router();

modulesRouter.get(
  "/modules",
  asyncHandler((req, res) => {
    const category = typeof req.query.category === "string" ? req.query.category : undefined;
    const modules = category
      ? listModuleRegistry().filter((module) => module.category === category)
      : listModuleRegistry();

    return ok(res, modules);
  })
);

modulesRouter.get(
  "/modules/:id",
  asyncHandler((req, res) => ok(res, getModuleById(req.params.id)))
);
