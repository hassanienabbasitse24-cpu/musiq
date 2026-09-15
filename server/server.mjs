import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { rateLimiter } from './middleware/rateLimiter.js';
import jamendoRouter from './routes/jamendo.js';
import youtubeRouter from './routes/youtube.js';

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(rateLimiter);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'musiq-backend', sources: ['jamendo', 'youtube'] });
});

app.use('/jamendo', jamendoRouter);
app.use('/youtube', youtubeRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.use((err, _req, res, _next) => {
  console.error('[ERROR]', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

export default app;

const PORT = process.env.PORT || 3000;
if (process.argv[1] && process.argv[1].endsWith('server.js')) {
  app.listen(PORT, () => {
    console.log(`Musiq backend running on http://localhost:${PORT}`);
  });
}
