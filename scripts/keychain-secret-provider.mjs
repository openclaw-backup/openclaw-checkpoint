#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const SERVICE_MAP = {
  gatewayToken: {
    account: 'openclaw-gateway',
    service: 'openclaw-gateway-token',
  },
  discordBotToken: {
    account: 'openclaw-discord',
    service: 'openclaw-discord-bot-token',
  },
};

function readStdin() {
  return readFileSync(0, 'utf8');
}

function loadRequest() {
  const raw = readStdin().trim();
  if (!raw) throw new Error('missing request payload');
  return JSON.parse(raw);
}

function readKeychainSecret({ account, service }) {
  return execFileSync(
    'security',
    ['find-generic-password', '-a', account, '-s', service, '-w'],
    { encoding: 'utf8' },
  ).trim();
}

function main() {
  const req = loadRequest();
  const ids = Array.isArray(req.ids) ? req.ids : [];
  const values = {};
  const errors = {};

  for (const id of ids) {
    const mapping = SERVICE_MAP[id];
    if (!mapping) {
      errors[id] = { message: `unknown secret id: ${id}` };
      continue;
    }

    try {
      values[id] = readKeychainSecret(mapping);
    } catch (error) {
      errors[id] = { message: error instanceof Error ? error.message : String(error) };
    }
  }

  const result = {
    protocolVersion: 1,
    values,
  };

  if (Object.keys(errors).length > 0) result.errors = errors;
  process.stdout.write(`${JSON.stringify(result)}\n`);
}

main();
