#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const SERVICE_MAP = {
  gatewayToken: {
    account: 'openclaw-gateway',
    service: 'openclaw-gateway-token',
    env: 'OPENCLAW_GATEWAY_TOKEN',
  },
  discordBotToken: {
    account: 'openclaw-discord',
    service: 'openclaw-discord-bot-token',
    env: 'OPENCLAW_DISCORD_BOT_TOKEN',
  },
};

const LOGIN_KEYCHAIN = '/Users/demo/Library/Keychains/login.keychain-db';
const RUNTIME_SECRET_DIR = join(homedir(), '.openclaw', 'runtime-secrets');

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
    ['find-generic-password', '-a', account, '-s', service, '-w', LOGIN_KEYCHAIN],
    { encoding: 'utf8' },
  ).trim();
}

function readRuntimeSecret(fileName) {
  const filePath = join(RUNTIME_SECRET_DIR, fileName);
  if (!existsSync(filePath)) return null;
  return readFileSync(filePath, 'utf8').trim();
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
      const runtimeSecret = readRuntimeSecret(`${id}.txt`);
      if (runtimeSecret) {
        values[id] = runtimeSecret;
        continue;
      }

      values[id] = readKeychainSecret(mapping);
    } catch (error) {
      const fallback = process.env[mapping.env];
      if (fallback) {
        values[id] = fallback;
      } else {
        errors[id] = { message: error instanceof Error ? error.message : String(error) };
      }
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
