import { Container } from "@/components/ui/Container";
import { PhoneMockup } from "@/components/ui/PhoneMockup";

type ShowcaseRow =
  | {
      title: string;
      paragraph: string;
      bullets: string[];
      image: string;
      imageAlt: string;
      layout: "single";
    }
  | {
      title: string;
      paragraph: string;
      bullets: string[];
      images: [string, string];
      imageAlt: string;
      layout: "double";
    };

const rows: ShowcaseRow[] = [
  {
    title: "Performance Tracking",
    paragraph:
      "See your match history, win rates, and patterns at a glance. No spreadsheets — just clarity.",
    bullets: [
      "Dashboard view of recent matches",
      "Trends across surfaces and opponents",
    ],
    image: "/screenshots/home-dashboard.jpg",
    imageAlt: "Home dashboard",
    layout: "single" as const,
  },
  {
    title: "Tactical Coach",
    paragraph:
      "Describe what went wrong and get tailored drills. AI-powered advice that fits your game.",
    bullets: [
      "Specific adjustments for your issues",
      "Drill plans with reps and goals",
    ],
    image: "/screenshots/tactical-coach.jpg",
    imageAlt: "Tactical coach",
    layout: "single" as const,
  },
  {
    title: "Pre-match Prep",
    paragraph:
      "Lock in before you step on court. Calm, repeatable routines that reduce nerves.",
    bullets: [
      "Guided pre-match checklists",
      "Mental cues that work under pressure",
    ],
    image: "/screenshots/pre-match-prep.jpg",
    imageAlt: "Pre-match prep",
    layout: "single" as const,
  },
  {
    title: "Match Debrief",
    paragraph:
      "Reflect right after a match while it&apos;s fresh. Turn raw outcomes into clear next steps.",
    bullets: [
      "Structured debrief prompts",
      "Links to tactics and prep for next time",
    ],
    image: "/screenshots/match-debrief.jpg",
    imageAlt: "Match debrief",
    layout: "single" as const,
  },
  {
    title: "Logging Options",
    paragraph:
      "Log matches your way — quick capture or detailed breakdown. Both feed the same insights.",
    bullets: [
      "Quick match log for fast entry",
      "Detailed match log for deep reflection",
    ],
    images: [
      "/screenshots/quick-match-log.jpg",
      "/screenshots/detailed-match-log.jpg",
    ],
    imageAlt: "Match logging options",
    layout: "double" as const,
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
              className={`grid gap-8 lg:grid-cols-2 lg:gap-12 lg:items-center ${
                i % 2 === 1 ? "lg:flex-row-reverse" : ""
              }`}
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
              <div className={`flex gap-4 justify-center ${i % 2 === 1 ? "lg:order-1" : ""}`}>
                {row.layout === "double" ? (
                  <div className="flex flex-wrap justify-center gap-4">
                    <PhoneMockup
                      src={row.images[0]}
                      alt={`${row.imageAlt} - Quick`}
                    />
                    <PhoneMockup
                      src={row.images[1]}
                      alt={`${row.imageAlt} - Detailed`}
                    />
                  </div>
                ) : (
                  <PhoneMockup src={row.image} alt={row.imageAlt} />
                )}
              </div>
            </div>
          ))}
        </div>
      </Container>
    </section>
  );
}
