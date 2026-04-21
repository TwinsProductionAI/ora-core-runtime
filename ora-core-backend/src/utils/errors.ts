export class HttpError extends Error {
  public readonly statusCode: number;
  public readonly details?: unknown;

  constructor(statusCode: number, message: string, details?: unknown) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
  }
}

export function notFound(message = "Resource not found"): HttpError {
  return new HttpError(404, message);
}

export function badRequest(message = "Invalid request", details?: unknown): HttpError {
  return new HttpError(400, message, details);
}
