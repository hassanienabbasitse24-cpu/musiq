const JAMENDO_CLIENT_ID = '22ce9a72';
const JAMENDO_BASE = 'https://api.jamendo.com/v3.0';

export async function searchJamendo(query, { limit = 20, offset = 0 } = {}) {
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

export async function browseJamendo({ limit = 20, offset = 0, order = 'popularity_total' } = {}) {
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

export async function getJamendoTrack(trackId) {
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
