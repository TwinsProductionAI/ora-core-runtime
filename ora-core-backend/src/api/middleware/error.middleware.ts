import type { ErrorRequestHandler, RequestHandler } from "express";
import { HttpError } from "../../utils/errors.js";

export const notFoundMiddleware: RequestHandler = (req, _res, next) => {
  next(new HttpError(404, `Route not found: ${req.method} ${req.path}`));
};

export const errorMiddleware: ErrorRequestHandler = (err, _req, res, _next) => {
  const statusCode = err instanceof HttpError ? err.statusCode : 500;
  const message = err instanceof Error ? err.message : "Unknown error";
  const details = err instanceof HttpError ? err.details : undefined;

  res.status(statusCode).json({
    success: false,
    error: {
      message,
      ...(details ? { details } : {})
    }
  });
};
