#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

node <<'NODE'
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const relativePath = 'scrapforge-pages/privacy.html';
const html = fs.readFileSync(relativePath, 'utf8');
for (const phrase of [
  ['Ad', 'Mob'].join(''),
  ['advertising', ' identifier'].join(''),
  ['ad personalization', ' consent'].join(''),
  ['App Tracking', ' Transparency'].join(''),
]) {
  if (html.toLowerCase().includes(phrase.toLowerCase())) {
    throw new Error(`stale ScrapForge advertising statement remains: ${phrase}`);
  }
}
for (const phrase of [
  'Last updated: July 22, 2026',
  'does not include advertising',
  'All game progress stays on your device',
  'does not collect data from the app',
]) {
  if (!html.includes(phrase)) throw new Error(`required ScrapForge statement missing: ${phrase}`);
}

const server = http.createServer((request, response) => {
  if (request.url !== '/scrapforge-pages/privacy.html') {
    response.writeHead(404).end();
    return;
  }
  response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
  response.end(fs.readFileSync(path.join(process.cwd(), relativePath)));
});
server.listen(0, '127.0.0.1', async () => {
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}/scrapforge-pages/privacy.html`);
    const body = await response.text();
    if (!response.ok || body !== html) throw new Error('served ScrapForge privacy page differs from verified source');
    server.close(() => process.exit(0));
  } catch (error) {
    server.close(() => {
      console.error(error);
      process.exit(1);
    });
  }
});
NODE
