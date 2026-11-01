import app from './app.js';
import { config } from './config/env.js';

app.listen(config.port, '0.0.0.0', () => {
  console.log(`🚀 Bun Atelier Backend running on port ${config.port} (0.0.0.0)`);
  console.log(`📡 Health Check: http://localhost:${config.port}/api/health`);
  console.log(`🤖 Gemini Chatbot: http://localhost:${config.port}/api/support/chat`);
});
