import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

export function Pricing() {
  return (
    <section className="py-16 sm:py-24">
      <Container>
        <div className="grid gap-6 md:grid-cols-2 max-w-2xl mx-auto">
          <Card className="border-[var(--blue)]/30 bg-[var(--card2)] ring-1 ring-[var(--blue)]/20">
            <h3 className="text-xl font-semibold mb-2">Founder Access</h3>
            <p className="text-2xl font-bold text-[var(--blue)] mb-2">
              £4.99/month
            </p>
            <p className="text-[var(--muted)] text-sm mb-4">
              First 200 players, locked in permanently
            </p>
            <p className="text-xs text-[var(--muted)]">
              Payment opens after App Store approval.
            </p>
          </Card>
          <Card className="opacity-90">
            <h3 className="text-xl font-semibold mb-2 text-[var(--muted)]">
              Regular Pricing
            </h3>
            <p className="text-2xl font-bold mb-2">£9.99/month</p>
            <p className="text-[var(--muted)] text-sm mb-4">or £69/year</p>
            <p className="text-xs text-[var(--muted)]">
              Payment opens after App Store approval.
            </p>
          </Card>
        </div>
      </Container>
    </section>
  );
}
