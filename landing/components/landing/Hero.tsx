"use client";

import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";
import { PhoneMockup } from "@/components/ui/PhoneMockup";

function scrollToFounder() {
  document.getElementById("founder")?.scrollIntoView({ behavior: "smooth" });
}

export function Hero() {
  return (
    <section className="py-16 sm:py-24 lg:py-32">
      <Container>
        <div className="grid gap-12 lg:grid-cols-2 lg:gap-16 lg:items-center">
          <div>
            <h1 className="text-4xl font-bold tracking-tight sm:text-5xl lg:text-6xl text-[var(--text)] leading-tight">
              Win More Tennis Matches.<br />
              <span className="text-[var(--blue)]">Stop Guessing Why You Lost.</span>
            </h1>
            <p className="mt-6 text-lg text-[var(--muted)] max-w-xl leading-relaxed">
              Composure analyses your match data and gives you structured
              tactical adjustments, pattern detection, and a pre-match game plan
              — so you walk on court with clarity.
            </p>
            <div className="mt-8 flex flex-col gap-4 sm:flex-row sm:items-center">
              <Button onClick={scrollToFounder} className="w-full sm:w-auto">
                Secure Founder Pricing
              </Button>
              <p className="text-sm text-[var(--muted)]">
                £4.99/month • first 200 players • locked in permanently
              </p>
            </div>
          </div>
          <div className="flex justify-center lg:justify-end">
            <PhoneMockup
              src="/screenshots/home-dashboard.png"
              alt="Composure home dashboard"
            />
          </div>
        </div>
      </Container>
    </section>
  );
}
