import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

export function Pillars() {
  const pillars = [
    {
      title: "Tactical Coach",
      desc: "Turn tennis match issues into specific drills and adjustments.",
    },
    {
      title: "Match Debrief",
      desc: "Debrief what happened and what to work on before your next match.",
    },
    {
      title: "Pre-match Prep",
      desc: "A calm pre-match plan built around your primary weapon.",
    },
  ];

  return (
    <section className="py-16 sm:py-24">
      <Container>
        <h2 className="text-3xl font-bold text-center mb-12 sm:text-4xl">
          A system between matches.
        </h2>
        <div className="grid gap-8 md:grid-cols-3">
          {pillars.map((p) => (
            <Card key={p.title}>
              <h3 className="text-xl font-semibold mb-2">{p.title}</h3>
              <p className="text-[var(--muted)]">{p.desc}</p>
            </Card>
          ))}
        </div>
      </Container>
    </section>
  );
}
