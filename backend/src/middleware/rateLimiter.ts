import rateLimit from 'express-rate-limit';

export const chatRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  limit: 30, // max 30 requests per minute per IP
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Terlalu banyak permintaan dalam waktu singkat. Mohon tunggu 1 menit sebelum mengirim pesan lagi.',
  },
});
