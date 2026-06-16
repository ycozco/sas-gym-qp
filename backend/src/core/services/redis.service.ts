import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { getOptionalEnv } from '../config/env';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: Redis;
  private readonly logger = new Logger(RedisService.name);

  onModuleInit() {
    const redisUrl = this.getRedisUrl();
    this.logger.log(`Conectando a Redis en ${redisUrl}`);
    this.client = new Redis(redisUrl, {
      maxRetriesPerRequest: 3,
    });

    this.client.on('connect', () => {
      this.logger.log('Conexión con Redis establecida exitosamente.');
    });

    this.client.on('error', (err) => {
      this.logger.error('Error en el cliente de Redis:', err);
    });
  }

  async onModuleDestroy() {
    if (this.client) {
      this.logger.log('Cerrando conexión con Redis...');
      await this.client.quit();
    }
  }

  getClient(): Redis {
    return this.client;
  }

  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<string> {
    if (ttlSeconds) {
      return this.client.set(key, value, 'EX', ttlSeconds);
    }
    return this.client.set(key, value);
  }

  async del(key: string): Promise<number> {
    return this.client.del(key);
  }

  async exists(key: string): Promise<number> {
    return this.client.exists(key);
  }

  /**
   * Incrementa una clave en Redis y establece un TTL (Tiempo de Vida) si es la primera vez.
   */
  async incrWithTtl(key: string, ttlSeconds: number): Promise<number> {
    const val = await this.client.incr(key);
    if (val === 1) {
      await this.client.expire(key, ttlSeconds);
    }
    return val;
  }

  private getRedisUrl(): string {
    const configuredUrl = getOptionalEnv('REDIS_URL');
    if (configuredUrl) return configuredUrl;

    const host = getOptionalEnv('REDIS_HOST', 'localhost');
    const port = getOptionalEnv('REDIS_PORT', '6379');
    const password = getOptionalEnv('REDIS_PASSWORD');
    const encodedPassword = password ? `:${encodeURIComponent(password)}@` : '';
    return `redis://${encodedPassword}${host}:${port}`;
  }
}
