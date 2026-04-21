import { Router } from "express";
import { listRepos, refreshRegistryFromGithub } from "../services/github.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const reposRouter = Router();

reposRouter.get("/repos", asyncHandler((_req, res) => ok(res, listRepos())));

reposRouter.post("/repos/refresh", asyncHandler((_req, res) => ok(res, refreshRegistryFromGithub())));
