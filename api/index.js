require('dotenv/config');
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();

// Rate limiter
const rateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});

// Jamendo service
const JAMENDO_CLIENT_ID = '22ce9a72';
const JAMENDO_BASE = 'https://api.jamendo.com/v3.0';

async function searchJamendo(query, { limit = 20, offset = 0 } = {}) {
  const url = `${JAMENDO_BASE}/tracks/?client_id=${JAMENDO_CLIENT_ID}&format=json&limit=${limit}&offset=${offset}&audioformat=mp32&search=${encodeURIComponent(query)}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Jamendo API returned ${res.status}`);
  const data = await res.json();
  const total = data.headers?.results_count || 0;
  const tracks = (data.results || []).map((t) => ({
    id: `jamendo_${t.id}`,
    title: t.name || 'Unknown',
    artist: t.artist_name || 'Unknown',
    album: t.album_name || '',
    imageUrl: t.image || null,
    audioUrl: t.audio || null,
    duration: t.duration ? t.duration * 1000 : 0,
    genre: t.musicinfo?.tags?.genres?.[0]?.name || '',
    licenseUrl: t.license_ccurl || '',
  }));
  return { tracks, total };
}

async function browseJamendo({ limit = 20, offset = 0, order = 'popularity_total' } = {}) {
  const url = `${JAMENDO_BASE}/tracks/?client_id=${JAMENDO_CLIENT_ID}&format=json&limit=${limit}&offset=${offset}&audioformat=mp32&order=${order}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Jamendo API returned ${res.status}`);
  const data = await res.json();
  const total = data.headers?.results_count || 0;
  const tracks = (data.results || []).map((t) => ({
    id: `jamendo_${t.id}`,
    title: t.name || 'Unknown',
    artist: t.artist_name || 'Unknown',
    album: t.album_name || '',
    imageUrl: t.image || null,
    audioUrl: t.audio || null,
    duration: t.duration ? t.duration * 1000 : 0,
    genre: t.musicinfo?.tags?.genres?.[0]?.name || '',
    licenseUrl: t.license_ccurl || '',
  }));
  return { tracks, total };
}

async function getJamendoTrack(trackId) {
  const url = `${JAMENDO_BASE}/tracks/?client_id=${JAMENDO_CLIENT_ID}&format=json&id=${trackId}&audioformat=mp32`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Jamendo API returned ${res.status}`);
  const data = await res.json();
  const t = data.results?.[0];
  if (!t) return null;
  return {
    id: `jamendo_${t.id}`,
    title: t.name || 'Unknown',
    artist: t.artist_name || 'Unknown',
    album: t.album_name || '',
    imageUrl: t.image || null,
    audioUrl: t.audio || null,
    duration: t.duration ? t.duration * 1000 : 0,
    genre: t.musicinfo?.tags?.genres?.[0]?.name || '',
    licenseUrl: t.license_ccurl || '',
  };
}

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(rateLimiter);

// Health
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'musiq-backend', sources: ['jamendo', 'youtube'] });
});

// Jamendo routes
app.get('/jamendo/search', async (req, res) => {
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

app.get('/jamendo/browse', async (req, res) => {
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

app.get('/jamendo/track/:id', async (req, res) => {
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

// YouTube search route
app.get('/youtube/search', async (req, res) => {
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

// 404
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, _req, res, _next) => {
  console.error('[ERROR]', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

module.exports = app;
