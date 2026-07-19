import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  allowedDevOrigins: ['127.0.0.1', 'localhost'],
  async rewrites() {
    const api = process.env.API_INTERNAL_BASE_URL ?? 'http://127.0.0.1:4000';
    return [
      { source: '/api/health', destination: `${api}/health` },
      { source: '/api/ready', destination: `${api}/ready` },
      { source: '/api/:path*', destination: `${api}/api/:path*` },
      { source: '/uploads/:path*', destination: `${api}/uploads/:path*` },
    ];
  },
};

export default nextConfig;
