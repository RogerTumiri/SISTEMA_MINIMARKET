export class AppError extends Error {
  public readonly code:       string;
  public readonly statusCode: number;
  public readonly details?:   any;
  public readonly field?:     string;

  constructor(
    code:       string,
    message:    string,
    statusCode: number = 500,
    details?:   any,
    field?:     string
  ) {
    super(message);
    this.name       = 'AppError';
    this.code       = code;
    this.statusCode = statusCode;
    this.details    = details;
    this.field      = field;

    Error.captureStackTrace(this, this.constructor);
  }
}

export function successResponse(res: any, data: any, message = 'OK', statusCode = 200, meta?: any) {
  return res.status(statusCode).json({
    success: true,
    data,
    message,
    ...(meta && { meta }),
    timestamp: new Date().toISOString(),
  });
}
