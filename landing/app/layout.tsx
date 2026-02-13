import type { Metadata } from "next";
import "./globals.css";
import { Navbar } from "@/components/landing/Navbar";
import { Footer } from "@/components/landing/Footer";

export const metadata: Metadata = {
  title: "Composure — Tennis. Clearer.",
  description:
    "Composure turns match outcomes into tactical adjustments and calm, repeatable routines — built for competitive players.",
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
    </html>
  );
}
