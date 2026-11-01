import { Router, Request, Response } from 'express';
import { geminiService } from '../services/geminiService.js';

const router = Router();

router.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    service: 'Bun Atelier Backend API',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    geminiConfigured: geminiService.isConfigured(),
  });
});

export default router;
