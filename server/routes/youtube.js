import { Router } from 'express';

const router = Router();

router.get('/search', async (req, res) => {
  try {
    const { q, limit = 10 } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }

    const apiKey = process.env.YOUTUBE_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'YouTube API key not configured' });
    }

    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&videoCategoryId=10&q=${encodeURIComponent(q.trim())}&key=${apiKey}&maxResults=${Math.min(parseInt(limit) || 10, 25)}`;

    const response = await fetch(url);
    if (!response.ok) {
      const err = await response.text();
      console.error('[YouTube] API error:', response.status, err);
      return res.status(502).json({ error: 'YouTube API error', details: err });
    }

    const data = await response.json();
    const items = (data.items || []).map((item) => ({
      videoId: item.id.videoId,
      title: item.snippet.title,
      artist: item.snippet.channelTitle,
      imageUrl: item.snippet.thumbnails?.high?.url || item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url || null,
      description: item.snippet.description,
      publishedAt: item.snippet.publishedAt,
    }));

    res.json({ results: items, total: data.pageInfo?.totalResults || items.length });
  } catch (err) {
    console.error('[YouTube Search]', err.message);
    res.status(500).json({ error: 'Failed to search YouTube', details: err.message });
  }
});

export default router;
