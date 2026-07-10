#!/usr/bin/env node
//
// Converts a TripleCheck graph dataset from the original loose `.js` globals
// into a single typed JSON bundle.
//
//   node tool/convert_data.js <source-dir> <output.json>
//
// The source files declare bare globals (`table`, `tableLinks`, `details`, ...)
// and were only ever meant to be loaded by <script> tags. Rather than parse
// them, run them in a sandbox and read the globals back out.

'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const sourceDir = process.argv[2];
const outputPath = process.argv[3];

if (!sourceDir || !outputPath) {
  console.error('usage: node tool/convert_data.js <source-dir> <output.json>');
  process.exit(64);
}

const SOURCES = [
  'data/nodes.js',
  'data/links.js',
  'data/details.js',
  'data/project.js',
  'data/coders.js',
  'data/plagiarism/page3_originality_details.js',
  'data/plagiarism/settings.js',
];

const sandbox = {};
vm.createContext(sandbox);

for (const relative of SOURCES) {
  const file = path.join(sourceDir, relative);
  // settings.js carries a UTF-8 BOM, which is a syntax error to the vm.
  const code = fs.readFileSync(file, 'utf8').replace(/^﻿/, '');
  vm.runInContext(code, sandbox, { filename: file });
}

// nodes.js is one flat array of 9-tuples.
const NODE_STRIDE = 9;

function requireGlobal(name) {
  if (!(name in sandbox)) throw new Error(`source files did not define "${name}"`);
  return sandbox[name];
}

const table = requireGlobal('table');
const tableLinks = requireGlobal('tableLinks');
const details = requireGlobal('details');
const coders = requireGlobal('coders');
const matches = requireGlobal('matches');
const userSettings = requireGlobal('userSettings');
const pinfo = requireGlobal('pinfo');
const phtml = requireGlobal('phtml');

if (table.length % NODE_STRIDE !== 0) {
  throw new Error(`nodes.js length ${table.length} is not a multiple of ${NODE_STRIDE}`);
}

const nodes = [];
for (let i = 0; i < table.length; i += NODE_STRIDE) {
  nodes.push({
    id: table[i],
    symbol: table[i + 1],
    name: table[i + 2],
    license: table[i + 3],
    column: table[i + 4],
    row: table[i + 5],
    tag: table[i + 6],
    riskyLicense: Boolean(table[i + 7]),
    hasCopyright: Boolean(table[i + 8]),
  });
}

const fileDetails = details.map((row) => ({
  id: row[0],
  sha1: row[1],
  size: row[2],
  linesOfCode: row[3],
  license: row[4],
  copyright: row[5],
  path: row[6],
}));

const links = tableLinks.map((pair) => ({ from: pair[0], to: pair[1] }));

// Integrity checks. A dangling id would silently render as a missing node.
const ids = new Set(nodes.map((n) => n.id));
const dangling = links.filter((l) => !ids.has(l.from) || !ids.has(l.to));
const selfLinks = links.filter((l) => l.from === l.to);
const detailIds = new Set(fileDetails.map((d) => d.id));
const missingDetails = nodes.filter((n) => !detailIds.has(n.id));

const bundle = {
  project: {
    name: pinfo.name,
    licence: pinfo.licence,
    conflicts: pinfo.conflicts,
    licences: pinfo.licences,
    complete: pinfo.complete,
    files: pinfo.files,
    linesOfCode: pinfo.loc,
    summary: phtml,
  },
  nodes,
  links,
  details: fileDetails,
  coders: coders.map((c) => ({
    id: c.id ?? '',
    name: c.name ?? '',
    lastName: c.lastName ?? '',
    imageSrc: c.imageSrc ?? '',
  })),
  matches,
  reviewStates: userSettings.userReviewData ?? [],
};

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(bundle, null, 2));

console.log(`nodes            ${nodes.length}`);
console.log(`links            ${links.length}`);
console.log(`details          ${fileDetails.length}`);
console.log(`coders           ${bundle.coders.length}`);
console.log(`match buckets    ${matches.length} (${matches.map((m) => m.type).join(', ')})`);
console.log(`review states    ${bundle.reviewStates.length}`);
console.log(`self-links       ${selfLinks.length}`);
console.log(`dangling links   ${dangling.length}`);
console.log(`missing details  ${missingDetails.length}`);
console.log(`wrote            ${outputPath} (${(fs.statSync(outputPath).size / 1024).toFixed(0)} KB)`);
