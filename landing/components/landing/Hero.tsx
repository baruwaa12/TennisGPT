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
              Stop Losing Tennis Matches<br />
              <span className="text-[var(--blue)]">You Should Be Winning.</span>
            </h1>
            <p className="mt-6 text-lg text-[var(--muted)] max-w-xl leading-relaxed">
              Composure analyses your match history, finds the patterns holding
              you back, and gives you a tactical plan for the next one.
            </p>
            <div className="mt-8 flex flex-col gap-4 sm:flex-row sm:items-center">
              <Button onClick={scrollToFounder} className="w-full sm:w-auto">
                Secure Founder Pricing
              </Button>
              <p className="text-sm text-[var(--muted)]">
                £4.99/month • first 200 players • locked in permanently
              </p>
            </div>
            <p className="mt-4 text-xs text-[var(--muted)]/70">
              Built for competitive players. Not a coaching gimmick.
            </p>
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
