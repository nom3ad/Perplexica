/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        hostname: 's2.googleusercontent.com',
      },
    ],
  },
  async rewrites() {
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
};

export default nextConfig;
