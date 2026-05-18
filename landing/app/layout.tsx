import type { Metadata } from "next";
import "./globals.css";
import { Navbar } from "@/components/landing/Navbar";
import { Footer } from "@/components/landing/Footer";
import { GoogleAnalytics } from "@next/third-parties/google";
import { GA_MEASUREMENT_ID, SITE_URL } from "@/lib/site";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Composure — Tennis. Clearer.",
    template: "%s — Composure",
  },
  description:
    "Composure is an elite tennis performance app that turns match outcomes into tactical adjustments and calm, repeatable routines — built for competitive players.",
  openGraph: {
    type: "website",
    siteName: "Composure",
    title: "Composure — Tennis. Clearer.",
    description:
      "Tactical coaching, emotional resets, and match analysis for competitive tennis players.",
    url: SITE_URL,
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "Composure — AI Tennis Coach",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Composure — Tennis. Clearer.",
    description:
      "Tactical coaching, emotional resets, and match analysis for competitive tennis players.",
    images: ["/og-image.png"],
  },
  alternates: {
    canonical: SITE_URL,
  },
  verification: {
    google: "mBIGJ9bUMtxhGpfCRi5zDEdKCFGqSvM5P-zv1q2ij8o",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-snippet": -1,
      "max-image-preview": "large",
      "max-video-preview": -1,
    },
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Navbar />
        <main>{children}</main>
        <Footer />
      </body>
      <GoogleAnalytics gaId={GA_MEASUREMENT_ID} />
    </html>
  );
}
