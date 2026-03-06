/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    unoptimized: false,
  },
  async rewrites() {
    return {
      afterFiles: [
        {
          source: "/app/:path((?!.*\\.).*)",
          destination: "/app/index.html",
        },
      ],
    };
  },
  async redirects() {
    return [
      {
        source: "/app",
        destination: "/app/",
        permanent: true,
      },
    ];
  },
};

module.exports = nextConfig;
