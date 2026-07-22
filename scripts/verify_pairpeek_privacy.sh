#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

node <<'NODE'
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const relativePath = 'pairpeek-pages/privacy.html';
const html = fs.readFileSync(relativePath, 'utf8');
if (/(^|[^\p{L}])memory([^\p{L}]|$)/iu.test(html)) {
  throw new Error('disputed standalone terminology remains in the published-policy source');
}
for (const phrase of [
  'Last updated: July 22, 2026',
  'card-pair matching game',
  'requests only non-personalized ads',
  "does not request Apple's App Tracking Transparency permission",
]) {
  if (!html.includes(phrase)) throw new Error(`required PairPeek statement missing: ${phrase}`);
}
for (const phrase of ['may also ask Apple', 'before personalized advertising']) {
  if (html.includes(phrase)) throw new Error(`stale PairPeek statement remains: ${phrase}`);
}

const server = http.createServer((request, response) => {
  if (request.url !== '/pairpeek-pages/privacy.html') {
    response.writeHead(404).end();
    return;
  }
  response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
  response.end(fs.readFileSync(path.join(process.cwd(), relativePath)));
});
server.listen(0, '127.0.0.1', async () => {
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}/pairpeek-pages/privacy.html`);
    const body = await response.text();
    if (!response.ok || body !== html) throw new Error('served PairPeek privacy page differs from verified source');
    server.close(() => process.exit(0));
  } catch (error) {
    server.close(() => {
      console.error(error);
      process.exit(1);
    });
  }
});
NODE
