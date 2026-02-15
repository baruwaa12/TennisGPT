import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

export function Problem() {
  return (
    <section className="py-16 sm:py-24 bg-[var(--bg2)]">
      <Container>
        <h2 className="text-3xl font-bold text-center mb-12 sm:text-4xl">
          Most players guess what went wrong.
        </h2>
        <div className="grid gap-6 md:grid-cols-3">
          <Card>
            <h3 className="text-lg font-semibold mb-2">
              Tight matches slip away
            </h3>
            <p className="text-[var(--muted)] text-sm">
              You win the easy points, then lose the tight games — and you can&apos;t
              name the exact tennis pattern causing it.
            </p>
          </Card>
          <Card>
            <h3 className="text-lg font-semibold mb-2">
              No clear tactical adjustments
            </h3>
            <p className="text-[var(--muted)] text-sm">
              After a match, you feel what went wrong, but you don&apos;t know what
              to change in shot selection, targets, or return positioning.
            </p>
          </Card>
          <Card>
            <h3 className="text-lg font-semibold mb-2">
              Mental dips repeat
            </h3>
            <p className="text-[var(--muted)] text-sm">
              The same pressure moments show up every set without a calm,
              repeatable routine you can execute.
            </p>
          </Card>
        </div>
      </Container>
    </section>
  );
}
