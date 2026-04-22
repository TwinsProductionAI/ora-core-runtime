import { Router } from "express";
import { getModuleById, listModuleRegistry } from "../modules/registry.js";
import { asyncHandler } from "../utils/async-handler.js";
import { badRequest } from "../utils/errors.js";
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
  asyncHandler((req, res) => {
    const moduleId = req.params.id;
    if (!moduleId) {
      throw badRequest("Missing module id.");
    }

    return ok(res, getModuleById(moduleId));
  })
);
