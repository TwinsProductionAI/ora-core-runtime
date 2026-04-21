import type { RequestHandler } from "express";
import type { ZodSchema } from "zod";
import { badRequest } from "../../utils/errors.js";

export function validateBody<T>(schema: ZodSchema<T>): RequestHandler {
  return (req, _res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return next(badRequest("Request body validation failed", result.error.flatten()));
    }

    req.body = result.data;
    return next();
  };
}
