"use client";

import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";

function scrollToFounder() {
  document.getElementById("founder")?.scrollIntoView({ behavior: "smooth" });
}

export function Navbar() {
  return (
    <nav className="sticky top-0 z-50 border-b border-[var(--border)] bg-[var(--bg)]/92 backdrop-blur-md">
      <Container className="flex h-16 items-center justify-between">
        <a href="/" className="flex items-baseline gap-2 text-xl font-semibold tracking-tight">
          <span>Composure</span>
          <span className="text-xs font-medium text-[var(--muted)]">Tennis</span>
        </a>
        <div className="flex items-center gap-2 sm:gap-4">
          <a
            href="/blog"
            className="rounded-lg px-3 py-2 text-sm font-medium text-[var(--text)] hover:bg-[var(--card2)] transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--blueGlow)]"
          >
            Blog
          </a>
          <a
            href="/app/"
            className="rounded-lg px-3 py-2 text-sm font-medium text-[var(--text)] hover:bg-[var(--card2)] transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--blueGlow)]"
          >
            Open App
          </a>
          <Button onClick={scrollToFounder}>Join Founder Access</Button>
        </div>
      </Container>
    </nav>
  );
}
