import type { Metadata } from "next";
import { blogPosts } from "@/lib/blog/posts";
import { Container } from "@/components/ui/Container";
import { Card } from "@/components/ui/Card";

export const metadata: Metadata = {
  title: "Blog — Composure",
  description:
    "Match clarity, composure, and repeatable patterns for competitive tennis players.",
};

function StatusPill({ status }: { status: "published" | "comingSoon" }) {
  const label = status === "published" ? "Published" : "Coming soon";
  const classes =
    status === "published"
      ? "border-emerald-400/30 bg-emerald-400/10 text-emerald-200"
      : "border-white/15 bg-white/5 text-[var(--muted)]";

  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium ${classes}`}
    >
      {label}
    </span>
  );
}

export default function BlogIndexPage() {
  return (
    <Container className="py-16">
      <div className="mx-auto max-w-[900px]">
        <div className="mb-10">
          <h1 className="text-3xl sm:text-4xl font-semibold tracking-tight">
            Blog
          </h1>
          <p className="mt-3 text-[var(--muted)]">
            A connected series on closing sets, preventing execution drift, and
            building calm, repeatable routines under pressure.
          </p>
        </div>

        <div className="grid gap-6">
          {blogPosts.map((post) => (
            <a key={post.slug} href={`/blog/${post.slug}`} className="group">
              <Card className="transition-colors group-hover:border-white/20">
                <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
                  <div>
                    <h2 className="text-xl font-semibold leading-snug">
                      {post.title}
                    </h2>
                    <p className="mt-2 text-[var(--muted)]">
                      {post.description}
                    </p>
                  </div>

                  <div className="shrink-0 flex sm:flex-col sm:items-end gap-3 sm:gap-2">
                    <StatusPill status={post.status} />
                    <span className="text-xs text-[var(--muted)]">
                      {post.publishedAt}
                    </span>
                  </div>
                </div>
              </Card>
            </a>
          ))}
        </div>
      </div>
    </Container>
  );
}

