import { Container } from "@/components/ui/Container";
import { PhoneMockup } from "@/components/ui/PhoneMockup";

const rows = [
  {
    title: "Tactical Coach",
    paragraph:
      "Get structured, analytical feedback after every match. Pattern detection across your history surfaces what you can't see yourself.",
    bullets: [
      "AI-powered recommendations with clear reasoning",
      "Multi-match pattern detection with frequency tracking",
    ],
    image: "/screenshots/tactical-coach.png",
    imageAlt: "Tactical coach results showing pattern detection and recommendations",
  },
  {
    title: "Pre-Match Prep",
    paragraph:
      "Build your game plan around a primary weapon. Define your serve strategy, opponent weakness hypothesis, and first two service games before you step on court.",
    bullets: [
      "Weapon-based strategy system",
      "Structured routines you can repeat under pressure",
    ],
    image: "/screenshots/pre-match-prep.png",
    imageAlt: "Pre-match prep with weapon selection system",
  },
  {
    title: "Match Debrief",
    paragraph:
      "Structured reflection immediately after a match. Select what happened, and Composure turns it into actionable tactical adjustments.",
    bullets: [
      "Guided debrief prompts for common match scenarios",
      "Feeds directly into pattern tracking",
    ],
    image: "/screenshots/match-debrief.png",
    imageAlt: "Match debrief with structured reflection prompts",
  },
  {
    title: "Quick Match Log",
    paragraph:
      "Log a match in under 30 seconds. Score, result, surface — done. Every entry feeds your tactical history and pattern analysis.",
    bullets: [
      "Fast4 and standard format support",
      "Set-by-set score capture",
    ],
    image: "/screenshots/quick-match-log.png",
    imageAlt: "Quick match log with score entry",
  },
];

export function Showcase() {
  return (
    <section className="py-16 sm:py-24 bg-[var(--bg2)]">
      <Container>
        <div className="space-y-24">
          {rows.map((row, i) => (
            <div
              key={row.title}
              className="grid gap-8 lg:grid-cols-2 lg:gap-12 lg:items-center"
            >
              <div className={i % 2 === 1 ? "lg:order-2" : ""}>
                <h3 className="text-2xl font-bold mb-4">{row.title}</h3>
                <p className="text-[var(--muted)] mb-4">{row.paragraph}</p>
                <ul className="list-disc list-inside space-y-1 text-[var(--muted)] text-sm">
                  {row.bullets.map((b) => (
                    <li key={b}>{b}</li>
                  ))}
                </ul>
              </div>
              <div
                className={`flex justify-center ${
                  i % 2 === 1 ? "lg:order-1" : ""
                }`}
              >
                <PhoneMockup src={row.image} alt={row.imageAlt} />
              </div>
            </div>
          ))}
        </div>
      </Container>
    </section>
  );
}
