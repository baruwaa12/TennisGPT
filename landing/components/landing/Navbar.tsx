"use client";

import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";

function scrollToFounder() {
  document.getElementById("founder")?.scrollIntoView({ behavior: "smooth" });
}

export function Navbar() {
  return (
    <nav className="sticky top-0 z-50 border-b border-[var(--border)] bg-[var(--bg)]/95 backdrop-blur-sm">
      <Container className="flex h-16 items-center justify-between">
        <a href="/" className="flex items-baseline gap-2 text-xl font-semibold tracking-tight">
          <span>Composure</span>
          <span className="text-xs font-medium text-[var(--muted)]">Tennis</span>
        </a>
        <Button onClick={scrollToFounder}>Join Founder Access</Button>
      </Container>
    </nav>
  );
}
