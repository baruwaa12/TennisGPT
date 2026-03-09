import type { Metadata } from "next";
import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

export const metadata: Metadata = {
  title: "Privacy Policy — Composure",
  description:
    "How Composure collects, uses, and protects your information.",
};

const sections = [
  {
    title: "1. Information We Collect",
    content: [
      {
        heading: "Account Information",
        items: [
          "Email address (from Google or Apple Sign-In)",
          "Display name and profile photo",
          "Account creation date",
        ],
      },
      {
        heading: "Match Data",
        items: [
          "Match results (win/loss)",
          "Scores and opponent names",
          "Notes you add about matches",
          "Dates of matches",
        ],
      },
      {
        heading: "Usage Data",
        items: [
          "Features you use and how often",
          "AI prompts and responses",
          "App preferences and settings",
        ],
      },
      {
        heading: "Voice Input (if used)",
        items: [
          "Voice recordings are processed in real-time for transcription",
          "We do NOT store audio recordings",
          "Only the transcribed text is saved with your match notes",
        ],
      },
      {
        heading: "Device Information",
        items: [
          "Device type and operating system",
          "App version",
          "General location (country/region, not precise location)",
        ],
      },
    ],
  },
  {
    title: "2. How We Use Your Information",
    items: [
      "Provide personalised tennis insights and analysis",
      "Track your match history and progress",
      "Improve the AI coaching features",
      "Send important app updates (with your permission)",
      "Analyse app usage to improve features",
      "Provide customer support",
    ],
  },
  {
    title: "3. AI and Data Processing",
    items: [
      "Your match data and prompts are sent to our AI service for analysis",
      "The AI analyses your data to provide personalised advice",
      "We may use anonymised, aggregated data to improve AI quality",
      "Your individual data is never shared with other users",
    ],
  },
  {
    title: "4. Data Sharing",
    paragraphs: [
      "We do NOT sell your personal data.",
    ],
    content: [
      {
        heading: "Service Providers",
        items: [
          "Cloud hosting (to store your data securely)",
          "AI services (to provide analysis features)",
          "Analytics tools (to understand app usage)",
        ],
      },
    ],
    footnote:
      "These providers are bound by confidentiality agreements. We may also disclose data if required by law or to protect our rights.",
  },
  {
    title: "5. Data Security",
    items: [
      "Encrypted connections (HTTPS)",
      "Secure cloud infrastructure",
      "Access controls and authentication",
      "Regular security reviews",
    ],
    footnote:
      "No system is 100% secure. Please use a strong password and keep your device secure.",
  },
  {
    title: "6. Data Retention",
    items: [
      "Your data is kept as long as you have an active account",
      "Match history is retained to provide long-term insights",
      "You can delete your account and data at any time from Settings > Delete Account",
      "Deleted data is removed within 30 days",
    ],
  },
  {
    title: "7. Your Rights",
    items: [
      "Access your data (see what we have)",
      "Correct inaccurate data",
      "Delete your data",
      "Export your data",
      "Opt out of marketing communications",
    ],
    footnote:
      "To exercise these rights, use the in-app controls (including Settings > Delete Account) or contact ademolabaruwa09@gmail.com.",
  },
  {
    title: "8. Children's Privacy",
    paragraphs: [
      "Composure is suitable for tennis players of all ages. For users under 13 we collect minimal data necessary for the app to function, we do not knowingly collect sensitive personal information, and parents or guardians can contact us to manage their child's data.",
    ],
  },
  {
    title: "9. Third-Party Services",
    items: [
      "Google Sign-In (authentication)",
      "Apple Sign-In (authentication)",
      "OpenAI (AI analysis features)",
      "RevenueCat (subscription management)",
      "Apple / Google (app distribution and payments)",
    ],
    footnote: "Each service has its own privacy policy.",
  },
  {
    title: "10. Changes to This Policy",
    paragraphs: [
      "We may update this Privacy Policy from time to time. We will notify you of significant changes through the app or email. Continued use after changes means acceptance.",
    ],
  },
];

export default function PrivacyPage() {
  return (
    <Container className="py-16">
      <div className="mx-auto max-w-[720px]">
        {/* Header */}
        <div className="mb-10">
          <h1 className="text-3xl sm:text-4xl font-semibold tracking-tight">
            Privacy Policy
          </h1>
          <p className="mt-3 text-[var(--muted)]">Last updated: February 2026</p>
          <p className="mt-4 text-[var(--muted)] leading-relaxed">
            Your privacy matters to us. This Privacy Policy explains how
            Composure (&ldquo;we&rdquo;, &ldquo;us&rdquo;, &ldquo;our&rdquo;)
            collects, uses, and protects your information.
          </p>
        </div>

        {/* Sections */}
        <div className="grid gap-6">
          {sections.map((section) => (
            <Card key={section.title}>
              <h2 className="text-lg font-semibold mb-3">{section.title}</h2>

              {section.paragraphs?.map((p, i) => (
                <p key={i} className="text-[var(--muted)] text-sm leading-relaxed mb-3">
                  {p}
                </p>
              ))}

              {section.content?.map((block) => (
                <div key={block.heading} className="mb-4">
                  <p className="text-sm font-medium mb-1">{block.heading}</p>
                  <ul className="list-disc list-inside text-[var(--muted)] text-sm leading-relaxed space-y-0.5">
                    {block.items.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </div>
              ))}

              {section.items && (
                <ul className="list-disc list-inside text-[var(--muted)] text-sm leading-relaxed space-y-0.5">
                  {section.items.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              )}

              {section.footnote && (
                <p className="mt-3 text-[var(--muted)] text-xs leading-relaxed">
                  {section.footnote}
                </p>
              )}
            </Card>
          ))}
        </div>

        {/* Contact */}
        <Card className="mt-6">
          <h2 className="text-lg font-semibold mb-2">Contact Us</h2>
          <p className="text-[var(--muted)] text-sm mb-3">
            Privacy questions or concerns? We typically respond within 48 hours.
          </p>
          <a
            href="mailto:ademolabaruwa09@gmail.com"
            className="inline-flex items-center gap-2 rounded-lg bg-white/10 hover:bg-white/15 transition-colors px-4 py-2.5 text-sm font-medium"
          >
            ademolabaruwa09@gmail.com
          </a>
        </Card>
      </div>
    </Container>
  );
}
