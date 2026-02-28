import type { ReactNode } from "react";

export type BlogPostStatus = "published" | "comingSoon";

export interface BlogPost {
  slug: string;
  title: string;
  description: string;
  publishedAt: string; // ISO date (YYYY-MM-DD)
  status: BlogPostStatus;
  order: number; // lower = earlier in series
  content: () => ReactNode;
}

import { WhyYouLoseAfterLeading42 } from "@/content/blog/why-you-lose-tennis-matches-after-leading-4-2";
import { ExecutionDriftFivePercent } from "@/content/blog/execution-drift-the-5-percent";
import { NinetySecondReset } from "@/content/blog/90-second-reset-between-games";
import { PatternPlayUnderPressure } from "@/content/blog/pattern-play-under-pressure";
import { BreakPointPlaybook } from "@/content/blog/break-point-playbook";

const POSTS = [
  {
    slug: "why-you-lose-tennis-matches-after-leading-4-2",
    title: "Why You Lose Tennis Matches After Leading 4–2 (And How To Close Sets Out)",
    description:
      "Being 4–2 up feels like control — but it’s where standards slip. Here’s what’s actually happening and how to close sets with repeatable execution.",
    publishedAt: "2026-02-24",
    status: "published",
    order: 1,
    content: WhyYouLoseAfterLeading42,
  },
  {
    slug: "execution-drift-the-5-percent",
    title: "Execution Drift: The 5% That Costs You Matches (And How To Spot It Early)",
    description:
      "The swing rarely starts with a collapse — it starts with tiny drops in standards. Learn how to diagnose execution drift and correct it before momentum flips.",
    publishedAt: "2026-02-25",
    status: "published",
    order: 2,
    content: ExecutionDriftFivePercent,
  },
  {
    slug: "90-second-reset-between-games",
    title: "The 90‑Second Reset Between Games: A Routine for Tight Moments",
    description:
      "A simple between-games routine that keeps intensity, footwork, and decision-making stable — especially when you’re trying to close a set.",
    publishedAt: "2026-02-26",
    status: "published",
    order: 3,
    content: NinetySecondReset,
  },
  {
    slug: "pattern-play-under-pressure",
    title: "Pattern Play Under Pressure: How to Repeat What Built the Lead",
    description:
      "Closing isn’t about inventing — it’s about repeating. Here’s how to identify your lead-building patterns and keep running them under pressure.",
    publishedAt: "2026-02-27",
    status: "published",
    order: 4,
    content: PatternPlayUnderPressure,
  },
  {
    slug: "break-point-playbook",
    title: "Break‑Point Playbook: What to Do at 30‑30, Deuce, and Break Points",
    description:
      "The points that decide sets need a plan. Build a simple playbook for serve/return patterns, targets, and cues on the biggest points.",
    publishedAt: "2026-02-28",
    status: "published",
    order: 5,
    content: BreakPointPlaybook,
  },
] satisfies BlogPost[];

export const blogPosts = [...POSTS].sort((a, b) => a.order - b.order);

export function getBlogPost(slug: string) {
  return blogPosts.find((p) => p.slug === slug);
}

export function getBlogSlugs() {
  return blogPosts.map((p) => p.slug);
}

