import { Router } from "express";
import { validateBody } from "../api/middleware/validation.middleware.js";
import { CompileRequestSchema } from "../schemas/request.schema.js";
import { compileDirectPrompt, compileMaster, compileProjectMd } from "../services/compiler.service.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ok } from "../utils/http.js";

export const compileRouter = Router();

compileRouter.post(
  "/compile/direct",
  validateBody(CompileRequestSchema),
  asyncHandler((req, res) => ok(res, compileDirectPrompt(req.body)))
);

compileRouter.post(
  "/compile/md",
  validateBody(CompileRequestSchema),
  asyncHandler((req, res) => ok(res, compileProjectMd(req.body)))
);

compileRouter.post(
  "/compile/master",
  validateBody(CompileRequestSchema),
  asyncHandler((req, res) => ok(res, compileMaster(req.body)))
);
