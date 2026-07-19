const path = require('node:path');

const root = path.resolve(__dirname, '..');

module.exports = {
  apps: [
    {
      name: 'henaqena-api',
      cwd: path.join(root, 'apps/api'),
      script: 'dist/server.js',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '500M',
      time: true,
      env_production: {
        NODE_ENV: 'production',
      },
    },
    {
      name: 'henaqena-web',
      cwd: path.join(root, 'apps/web'),
      script: '.next/standalone/server.js',
      node_args: '--env-file=.env.production',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '700M',
      time: true,
      env_production: {
        NODE_ENV: 'production',
        PORT: 3100,
        HOSTNAME: '127.0.0.1',
        API_INTERNAL_BASE_URL: 'http://127.0.0.1:4000',
      },
    },
  ],
};
