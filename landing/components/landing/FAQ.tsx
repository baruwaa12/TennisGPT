import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

const faqs = [
  {
    q: "What is Composure?",
    a: "Composure is a tennis app that helps competitive players turn match outcomes into tactical adjustments and calm, repeatable routines. It includes a tactical coach, match debrief, and pre-match prep tools.",
  },
  {
    q: "Who is it for?",
    a: "Competitive tennis players who want clarity between matches and more control under pressure. Whether you play leagues, tournaments, or serious rec matches, Composure helps you stop guessing and start improving.",
  },
  {
    q: "When does payment start?",
    a: "Payment starts immediately through the App Store when you subscribe.",
  },
  {
    q: "What happens after I join?",
    a: "You'll receive confirmation by email so you can claim your founder rate and start using Composure right away.",
  },
  {
    q: "Can I cancel later?",
    a: "Yes. You can cancel your subscription at any time through the App Store. No long-term commitment required.",
  },
];

export function FAQ() {
  return (
    <section className="py-16 sm:py-24">
      <Container>
        <h2 className="text-3xl font-bold text-center mb-12 sm:text-4xl">
          FAQ
        </h2>
        <div className="max-w-2xl mx-auto space-y-6">
          {faqs.map((faq) => (
            <Card key={faq.q}>
              <h3 className="text-lg font-semibold mb-2">{faq.q}</h3>
              <p className="text-[var(--muted)]">{faq.a}</p>
            </Card>
          ))}
        </div>
      </Container>
    </section>
  );
}
