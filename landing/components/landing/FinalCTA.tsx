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
        <div className="text-center">
          <h2 className="text-3xl font-bold mb-6 sm:text-4xl">
            Train with clarity. Compete with control.
          </h2>
          <Button onClick={scrollToFounder}>Join Founder Access</Button>
        </div>
      </Container>
    </section>
  );
}
