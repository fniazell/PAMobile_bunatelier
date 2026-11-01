import { Router, Request, Response } from 'express';
import { geminiService } from '../services/geminiService.js';
import { validateChatInput } from '../middleware/validator.js';
import { chatRateLimiter } from '../middleware/rateLimiter.js';

const router = Router();

router.post(
  '/chat',
  chatRateLimiter,
  validateChatInput,
  async (req: Request, res: Response): Promise<void> => {
    if (!geminiService.isConfigured()) {
      res.status(503).json({
        success: false,
        error:
          'Gemini belum dikonfigurasi. Isi GEMINI_API_KEY di backend/.env, lalu jalankan ulang backend.',
      });
      return;
    }

    try {
      const { message, history, currencyContext } = req.body;

      const reply = await geminiService.generateSupportReply(
        message,
        Array.isArray(history) ? history : [],
        currencyContext
      );

      res.status(200).json({
        success: true,
        reply,
        timestamp: new Date().toISOString(),
      });
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown Gemini API error';
      console.error('Chat endpoint error:', errorMessage);

      const isTimeout = errorMessage.includes('timed out');

      res.status(isTimeout ? 504 : 502).json({
        success: false,
        error: isTimeout
          ? 'Permintaan ke Gemini AI membutuhkan waktu terlalu lama (timeout). Silakan coba lagi.'
          : 'Gemini tidak dapat menjawab saat ini. Periksa API key, model, dan koneksi internet backend.',
        ...(process.env.NODE_ENV !== 'production' && { details: errorMessage }),
        timestamp: new Date().toISOString(),
      });
    }
  }
);

export default router;
