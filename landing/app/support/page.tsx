import type { Metadata } from "next";
import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

export const metadata: Metadata = {
  title: "Support — Composure",
  description: "Get help with Composure. Send us your question and we'll get back to you.",
};

const faqs = [
  {
    q: "How do I log a match?",
    a: 'Tap "Log Match" on the home screen. Enter the result, score, and any notes. It takes about 30 seconds.',
  },
  {
    q: "How do I delete my account?",
    a: 'Open the app, go to Settings, scroll to the Account section and tap "Delete Account". This permanently removes your account and all associated data.',
  },
  {
    q: "Do I need a subscription to use Composure?",
    a: "No. All core features are fully accessible in the current version.",
  },
  {
    q: "Why does the app ask for microphone access?",
    a: "The microphone is used for voice input only — so you can speak your match notes instead of typing. The app never listens in the background.",
  },
  {
    q: "The AI feature isn't responding — what do I do?",
    a: "Make sure you have a stable internet connection. If the problem continues, close and reopen the app. If it still doesn't work, email us below.",
  },
];

export default function SupportPage() {
  return (
    <Container className="py-16">
      <div className="mx-auto max-w-[720px]">

        {/* Header */}
        <div className="mb-10">
          <h1 className="text-3xl sm:text-4xl font-semibold tracking-tight">
            Support
          </h1>
          <p className="mt-3 text-[var(--muted)]">
            Need help with Composure? We're here for you.
          </p>
        </div>

        {/* Contact card */}
        <Card className="mb-12">
          <h2 className="text-xl font-semibold mb-2">Contact us</h2>
          <p className="text-[var(--muted)] mb-4">
            Send your question, bug report, or feedback to our support email and
            we'll get back to you as soon as possible.
          </p>
          <a
            href="mailto:ademolabaruwa09@gmail.com"
            className="inline-flex items-center gap-2 rounded-lg bg-white/10 hover:bg-white/15 transition-colors px-4 py-2.5 text-sm font-medium"
          >
            ademolabaruwa09@gmail.com
          </a>
        </Card>

        {/* FAQ */}
        <div>
          <h2 className="text-xl font-semibold mb-6">Common questions</h2>
          <div className="grid gap-4">
            {faqs.map((item) => (
              <Card key={item.q}>
                <p className="font-medium mb-1">{item.q}</p>
                <p className="text-[var(--muted)] text-sm leading-relaxed">{item.a}</p>
              </Card>
            ))}
          </div>
        </div>

      </div>
    </Container>
  );
}
