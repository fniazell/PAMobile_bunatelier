import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import healthRoutes from './routes/healthRoutes.js';
import chatRoutes from './routes/chatRoutes.js';
import blockchainRoutes from './routes/blockchainRoutes.js';

const app = express();

// Security & Cross-Origin
app.use(cors({
  origin: '*', // Allow all clients (Flutter Web preview & mobile)
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body parsing with payload size limit
app.use(express.json({ limit: '20kb' }));

// API Routes
app.use('/api', healthRoutes);
app.use('/api/support', chatRoutes); // /api/support/chat
app.use('/api/ai', chatRoutes);      // /api/ai/chat (compatibility with ApiConstants.aiChat)
app.use('/api/blockchain', blockchainRoutes); // /api/blockchain/*

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.method} ${req.url} tidak ditemukan.`,
  });
});

// Global error handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Unhandled server error:', err?.message || err);
  res.status(500).json({
    success: false,
    error: 'Terjadi kesalahan internal pada server.',
  });
});

export default app;
