"use client";

import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";

function scrollToFounder() {
  document.getElementById("founder")?.scrollIntoView({ behavior: "smooth" });
}

export function FinalCTA() {
  return (
    <section className="py-16 sm:py-24 bg-[var(--bg2)]">
      <Container>
        <div className="text-center rounded-2xl border border-[var(--border)] bg-[var(--card)] p-10 sm:p-14">
          <h2 className="text-3xl font-bold mb-6 sm:text-4xl">
            Train with clarity. Compete with control.
          </h2>
          <p className="mx-auto mb-8 max-w-xl text-[var(--muted)]">
            Build composure under pressure with tactical preparation and match-by-match reflection.
          </p>
          <Button onClick={scrollToFounder}>Join Founder Access</Button>
        </div>
      </Container>
    </section>
  );
}
