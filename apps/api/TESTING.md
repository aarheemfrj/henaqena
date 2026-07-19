# Testing the Hena Qena API

## Running Tests Locally

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ installed

### Setup & Run

```bash
cd apps/api

# Option 1: Automated (recommended)
npm run test:setup    # Start PostgreSQL in Docker
npm test              # Run tests
npm run test:teardown # Stop PostgreSQL

# Or all-in-one:
npm run test:db

# Option 2: Watch mode (keep database running)
npm run test:setup
npm run test:watch
npm run test:teardown
```

## CI/CD Pipeline

Tests run automatically on:
- Push to `main` or `develop`
- Pull requests to `main` or `develop`
- Changes in `apps/api/` or `.github/workflows/test.yml`

The CI pipeline uses GitHub Actions with PostgreSQL service and includes:
- TypeScript compilation
- Jest unit tests
- Coverage reports (uploaded to Codecov)
- Flutter analyzer for mobile app
- Build artifacts for API (main branch only)

## Troubleshooting

### "Can't reach database server"
```bash
# Ensure test container is running
docker-compose -f docker-compose.test.yml ps

# If not running, start it
npm run test:setup

# Check logs
docker-compose -f docker-compose.test.yml logs postgres
```

### "Port 5434 already in use"
```bash
# Kill the existing container
docker-compose -f docker-compose.test.yml down -v

# Try again
npm run test:db
```

### "Tests pass locally but fail in CI"
Check `DATABASE_URL` environment variable in `.github/workflows/test.yml`. CI uses:
- Host: `localhost`
- Port: `5432`
- Database: `henaqena`
- User/Pass: `henaqena`

## Writing Tests

Place test files in `src/__tests__/` with `.test.ts` extension.

Example:
```typescript
import request from 'supertest';
import { createApp } from '../app';

describe('API Endpoint', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createApp();
  });

  it('should return success', async () => {
    const response = await request(app)
      .get('/api/health')
      .expect(200);

    expect(response.body.ok).toBe(true);
  });
});
```

## Coverage

View coverage reports:
```bash
npm run test:coverage
open coverage/lcov-report/index.html
```
