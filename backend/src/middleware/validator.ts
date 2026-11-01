import { Request, Response, NextFunction } from 'express';

export function validateChatInput(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const { message, history } = req.body;

  if (message === undefined || message === null) {
    res.status(400).json({
      success: false,
      error: 'Parameter "message" wajib diisi.',
    });
    return;
  }

  if (typeof message !== 'string') {
    res.status(400).json({
      success: false,
      error: 'Parameter "message" harus berupa teks (string).',
    });
    return;
  }

  const trimmed = message.trim();
  if (trimmed.length === 0) {
    res.status(400).json({
      success: false,
      error: 'Pesan tidak boleh kosong.',
    });
    return;
  }

  if (trimmed.length > 1000) {
    res.status(400).json({
      success: false,
      error: 'Pesan terlalu panjang. Maksimal 1000 karakter per pesan.',
    });
    return;
  }

  if (history !== undefined) {
    if (!Array.isArray(history)) {
      res.status(400).json({
        success: false,
        error: 'Parameter "history" harus berupa array percakapan.',
      });
      return;
    }

    if (history.length > 30) {
      res.status(400).json({
        success: false,
        error: 'Riwayat percakapan melebihi batas maksimal (30 pesan).',
      });
      return;
    }
  }

  next();
}
