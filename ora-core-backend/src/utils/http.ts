import type { Response } from "express";

export function ok<T>(res: Response, data: T, meta?: Record<string, unknown>): Response {
  return res.json({
    success: true,
    data,
    ...(meta ? { meta } : {})
  });
}
