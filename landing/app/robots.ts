import type { MetadataRoute } from "next";

// TODO: Replace with your actual production domain (same as in sitemap.ts)
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "https://composuretennis.com";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    sitemap: `${SITE_URL}/sitemap.xml`,
  };
}
