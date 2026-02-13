"use client";

import { useState, FormEvent } from "react";
import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";

export function FounderAccess() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setSuccess(false);

    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });

      if (res.ok) {
        setSuccess(true);
        setEmail("");
      } else {
        const data = await res.json().catch(() => ({}));
        alert(data.error || "Something went wrong. Please try again.");
      }
    } catch {
      alert("Something went wrong. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <section
      id="founder"
      className="py-16 sm:py-24 bg-[var(--bg2)] scroll-mt-20"
    >
      <Container>
        <div className="max-w-xl mx-auto text-center">
          <h2 className="text-3xl font-bold mb-6 sm:text-4xl">
            Founder Access
          </h2>
          <p className="text-[var(--muted)] mb-4">
            Founder rate: £4.99/month (first 200 players, locked in permanently).
          </p>
          <p className="text-[var(--muted)] mb-6">
            Regular pricing will be £9.99/month or £69/year.
          </p>
          <p className="text-[var(--muted)] mb-8">
            Enter your email to secure your founder spot. You&apos;ll receive
            payment details once the app is approved.
          </p>

          {success ? (
            <p className="text-[var(--blue)] font-medium py-4">
              Founder spot secured. You&apos;ll receive payment details when
              Composure is approved.
            </p>
          ) : (
            <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-3 max-w-md mx-auto">
              <label htmlFor="founder-email" className="sr-only">
                Email address
              </label>
              <input
                id="founder-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                required
                disabled={loading}
                className="flex-1 rounded-lg border border-[var(--border)] bg-[var(--card)] px-4 py-3 text-[var(--text)] placeholder-[var(--muted)] focus:outline-none focus:ring-2 focus:ring-[var(--blue)] focus:border-transparent disabled:opacity-50"
              />
              <Button type="submit" disabled={loading} className="w-full sm:w-auto">
                {loading ? "Joining…" : "Join Founder Access"}
              </Button>
            </form>
          )}
        </div>
      </Container>
    </section>
  );
}
