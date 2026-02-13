import { Container } from "@/components/ui/Container";

export function Pillars() {
  const pillars = [
    {
      title: "Tactical Coach",
      desc: "Turn match issues into specific drills and adjustments.",
    },
    {
      title: "Match Debrief",
      desc: "Reflect on what happened and what to work on next.",
    },
    {
      title: "Pre-match Prep",
      desc: "Calm routines that help you show up ready.",
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
            <div
              key={p.title}
              className="rounded-xl border border-[var(--border)] bg-[var(--card)] p-6"
            >
              <h3 className="text-xl font-semibold mb-2">{p.title}</h3>
              <p className="text-[var(--muted)]">{p.desc}</p>
            </div>
          ))}
        </div>
      </Container>
    </section>
  );
}
