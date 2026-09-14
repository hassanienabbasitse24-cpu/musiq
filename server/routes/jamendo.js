import { Router } from 'express';
import { searchJamendo, browseJamendo, getJamendoTrack } from '../services/jamendoService.js';

const router = Router();

router.get('/search', async (req, res) => {
  try {
    const { q, limit = 20, offset = 0 } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }

    const result = await searchJamendo(q.trim(), {
      limit: Math.min(parseInt(limit) || 20, 50),
      offset: parseInt(offset) || 0,
    });

    res.json(result);
  } catch (err) {
    console.error('[JAMENDO SEARCH]', err.message);
    res.status(502).json({ error: 'Failed to search Jamendo', details: err.message });
  }
});

router.get('/browse', async (req, res) => {
  try {
    const { limit = 20, offset = 0, order = 'popularity_total' } = req.query;

    const result = await browseJamendo({
      limit: Math.min(parseInt(limit) || 20, 50),
      offset: parseInt(offset) || 0,
      order,
    });

    res.json(result);
  } catch (err) {
    console.error('[JAMENDO BROWSE]', err.message);
    res.status(502).json({ error: 'Failed to browse Jamendo', details: err.message });
  }
});

router.get('/track/:id', async (req, res) => {
  try {
    const track = await getJamendoTrack(req.params.id);
    if (!track) {
      return res.status(404).json({ error: 'Track not found' });
    }
    res.json(track);
  } catch (err) {
    console.error('[JAMENDO TRACK]', err.message);
    res.status(502).json({ error: 'Failed to get track', details: err.message });
  }
});

export default router;
