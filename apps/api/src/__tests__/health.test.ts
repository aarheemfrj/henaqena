import request from 'supertest';
import { createApp } from '../app';
import express from 'express';

describe('Health Check Endpoint', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createApp() as express.Application;
  });

  describe('GET /health', () => {
    it('should return 200 with ok status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body).toEqual({
        ok: true,
        service: 'hena-qena-api'
      });
    });

    it('should have correct content type', async () => {
      await request(app)
        .get('/health')
        .expect('Content-Type', /json/);
    });

    it('should respond quickly', async () => {
      const start = Date.now();
      await request(app).get('/health');
      const duration = Date.now() - start;
      expect(duration).toBeLessThan(100);
    });
  });

  describe('404 Handling', () => {
    it('should return 404 for non-existent endpoint', async () => {
      const response = await request(app)
        .get('/api/nonexistent')
        .expect(404);

      expect(response.body.message).toBe('المسار غير موجود');
    });
  });
});
