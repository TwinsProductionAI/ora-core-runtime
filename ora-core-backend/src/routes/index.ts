import { Router } from "express";
import { capabilitiesRouter } from "./capabilities.routes.js";
import { compileRouter } from "./compile.routes.js";
import { essencesRouter } from "./essences.routes.js";
import { estimateRouter } from "./estimate.routes.js";
import { healthRouter } from "./health.routes.js";
import { modulesRouter } from "./modules.routes.js";
import { needsRouter } from "./needs.routes.js";
import { plansRouter } from "./plans.routes.js";
import { reposRouter } from "./repos.routes.js";
import { selectionRouter } from "./selection.routes.js";

export const router = Router();

router.use(healthRouter);
router.use(reposRouter);
router.use(modulesRouter);
router.use(essencesRouter);
router.use(capabilitiesRouter);
router.use(plansRouter);
router.use(needsRouter);
router.use(selectionRouter);
router.use(compileRouter);
router.use(estimateRouter);