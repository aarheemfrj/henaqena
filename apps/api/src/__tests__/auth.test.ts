import request from 'supertest';
import { createApp } from '../app';
import express from 'express';

describe('Authentication Endpoints', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createApp() as express.Application;
  });

  describe('POST /api/auth/register', () => {
    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({})
        .expect(400);

      expect(response.body.message).toBe('بيانات المدخلات غير صحيحة');
      expect(response.body.errors).toBeDefined();
    });

    it('should validate phone format', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'محمد علي',
          phone: '123',
          password: 'StrongPassword123'
        })
        .expect(400);

      expect(response.body.message).toBe('بيانات المدخلات غير صحيحة');
    });

    it('should validate password length', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'محمد علي',
          phone: '01001234567',
          password: 'short'
        })
        .expect(400);

      expect(response.body.message).toBe('بيانات المدخلات غير صحيحة');
    });

    it('should validate name length', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'ع',
          phone: '01001234567',
          password: 'ValidPassword123'
        })
        .expect(400);

      expect(response.body.message).toBe('بيانات المدخلات غير صحيحة');
    });

    it('should accept valid registration data', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'محمد علي',
          phone: '01001234567',
          email: 'test@example.com',
          password: 'ValidPassword123'
        });

      // Either 201 Created or 409 Conflict (if user already exists)
      expect([201, 409]).toContain(response.status);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should validate phone format or hit rate limit', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .set('X-Forwarded-For', '192.168.1.1') // Unique IP for this test
        .send({
          phone: 'invalid',
          password: 'password'
        });

      expect([400, 429]).toContain(response.status);
    });

    it('should require password or hit rate limit', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .set('X-Forwarded-For', '192.168.1.2') // Unique IP
        .send({
          phone: '01001234567'
        });

      expect([400, 429]).toContain(response.status);
    });

    it('should handle authentication', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .set('X-Forwarded-For', '192.168.1.3') // Unique IP
        .send({
          phone: '01099999999',
          password: 'WrongPassword123'
        });

      // Either auth error or rate limit
      expect([401, 429, 400]).toContain(response.status);
    });
  });

  describe('Rate Limiting', () => {
    it('should include rate limit headers', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .set('X-Forwarded-For', '192.168.1.100')
        .send({
          phone: '01022222222',
          password: 'test'
        });

      expect(response.headers['x-ratelimit-limit']).toBe('5');
      expect(response.headers['x-ratelimit-remaining']).toBeDefined();
    });
  });

  describe('Public Endpoints', () => {
    it('GET /api/areas should return list', async () => {
      const response = await request(app)
        .get('/api/areas')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });

    it('GET /api/categories should return list', async () => {
      const response = await request(app)
        .get('/api/categories')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });
  });
});

// Helper to check if value is in array
declare global {
  namespace jest {
    interface Matchers<R> {
      toBeOneOf(values: any[]): R;
    }
  }
}

expect.extend({
  toBeOneOf(received, values) {
    const pass = values.includes(received);
    return {
      pass,
      message: () =>
        `expected ${received} to be one of ${values.join(', ')}`
    };
  }
});
