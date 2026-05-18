/**
 * Site-wide runtime configuration for the landing page.
 *
 * Override per deploy via env vars:
 *   NEXT_PUBLIC_SITE_URL=https://composuretennis.com
 *   NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXX
 */

export const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://composuretennis.com";

export const GA_MEASUREMENT_ID =
  process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID ?? "G-VXLD9RYPR9";
