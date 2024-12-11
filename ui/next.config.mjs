/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    remotePatterns: [
      {
        hostname: 's2.googleusercontent.com',
      },
    ],
  },
  async rewrites() {
    if (process.env.NODE_ENV === 'development' || true) {
      console.warn('Development Mode!!! Using proxy for /api and /ws routes');
      // Proxy to Backend
      return [
        {
          source: '/ws',
          destination: 'http://localhost:3001/ws' 
        },
        {
          source: '/api/:path*',
          destination: 'http://localhost:3001/api/:path*'
        }
      ]
    } 
    console.error(`Mode: ${process.env.NODE_ENV}`); 
    return [];
  }
};

export default nextConfig;
