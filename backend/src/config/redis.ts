import Redis from 'ioredis';
import * as dotenv from 'dotenv';

dotenv.config();

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

export const redisClient = new Redis(redisUrl, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
  retryStrategy: (times) => {
    if (times > 5) return null;
    return Math.min(times * 100, 2000);
  },
});

redisClient.on('error', (err) => {
  console.error('[Redis] Error:', err.message);
});

// ─── Helpers para token blacklist ─────────────────────────
const TOKEN_BLACKLIST_PREFIX = 'bl:';
const REFRESH_TOKEN_PREFIX   = 'rt:';

export async function addToBlacklist(token: string, ttlSeconds: number): Promise<void> {
  try { await redisClient.setex(`${TOKEN_BLACKLIST_PREFIX}${token}`, ttlSeconds, '1'); } catch (e) {}
}

export async function isBlacklisted(token: string): Promise<boolean> {
  try {
    const result = await redisClient.get(`${TOKEN_BLACKLIST_PREFIX}${token}`);
    return result === '1';
  } catch (e) { return false; }
}

export async function storeRefreshToken(
  userId: string,
  token: string,
  ttlSeconds: number
): Promise<void> {
  try { await redisClient.setex(`${REFRESH_TOKEN_PREFIX}${userId}`, ttlSeconds, token); } catch (e) {}
}

export async function getStoredRefreshToken(userId: string): Promise<string | null> {
  try { return await redisClient.get(`${REFRESH_TOKEN_PREFIX}${userId}`); } catch (e) { return null; }
}

export async function deleteRefreshToken(userId: string): Promise<void> {
  try { await redisClient.del(`${REFRESH_TOKEN_PREFIX}${userId}`); } catch (e) {}
}
