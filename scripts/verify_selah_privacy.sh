#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

node <<'NODE'
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const relativePath = 'selah/privacy.html';
const html = fs.readFileSync(relativePath, 'utf8');
const forbiddenParts = [
  ['Ad', 'Mob'].join(''),
  ['App Tracking', ' Transparency'].join(''),
  ['advertising', ' identifier'].join(''),
  ['personalized', ' ads'].join(''),
  ['non-personalized', ' ads'].join(''),
  ['Ad privacy', ' options'].join(''),
  ['Google', ' UMP'].join(''),
];
for (const phrase of forbiddenParts) {
  if (html.toLowerCase().includes(phrase.toLowerCase())) {
    throw new Error(`stale advertising statement remains: ${phrase}`);
  }
}
for (const phrase of [
  'Effective date: July 22, 2026',
  'does not include advertising',
  'stored only on your device',
  'does not collect data from the app',
]) {
  if (!html.includes(phrase)) throw new Error(`required privacy statement missing: ${phrase}`);
}

const server = http.createServer((request, response) => {
  if (request.url !== '/selah/privacy.html') {
    response.writeHead(404).end();
    return;
  }
  response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
  response.end(fs.readFileSync(path.join(process.cwd(), relativePath)));
});
server.listen(0, '127.0.0.1', async () => {
  try {
    const { port } = server.address();
    const response = await fetch(`http://127.0.0.1:${port}/selah/privacy.html`);
    const body = await response.text();
    if (!response.ok || body !== html) throw new Error('served privacy page differs from verified source');
    server.close(() => process.exit(0));
  } catch (error) {
    server.close(() => {
      console.error(error);
      process.exit(1);
    });
  }
});
NODE

