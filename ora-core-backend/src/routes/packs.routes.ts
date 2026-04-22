import { Router } from "express";
import { getCoreFoundationPack, getMandatoryBaseModules, getModulePack, listModulePacks } from "../services/pack.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { badRequest } from "../utils/errors.js";
import { ok } from "../utils/http.js";

export const packsRouter = Router();

packsRouter.get(
  "/packs",
  asyncHandler((_req, res) => ok(res, listModulePacks()))
);

packsRouter.get(
  "/packs/base",
  asyncHandler((_req, res) => ok(res, {
    pack: getCoreFoundationPack(),
    modules: getMandatoryBaseModules()
  }))
);

packsRouter.get(
  "/packs/:id",
  asyncHandler((req, res) => {
    const packId = req.params.id;
    if (!packId) {
      throw badRequest("Missing pack id.");
    }

    return ok(res, getModulePack(packId));
  })
);
