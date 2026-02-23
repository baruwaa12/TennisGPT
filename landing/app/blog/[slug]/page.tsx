import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { Container } from "@/components/ui/Container";
import { blogPosts, getBlogPost, getBlogSlugs } from "@/lib/blog/posts";

export function generateStaticParams() {
  return getBlogSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const post = getBlogPost(slug);
  if (!post) return {};

  return {
    title: `${post.title} — Composure`,
    description: post.description,
  };
}

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

export default async function BlogPostPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = getBlogPost(slug);
  if (!post) notFound();

  const idx = blogPosts.findIndex((p) => p.slug === post.slug);
  const prev = idx > 0 ? blogPosts[idx - 1] : undefined;
  const next = idx >= 0 && idx < blogPosts.length - 1 ? blogPosts[idx + 1] : undefined;

  const Content = post.content;

  return (
    <Container className="py-16">
      <div className="mx-auto max-w-[760px]">
        <a
          href="/blog"
          className="inline-flex items-center text-sm text-[var(--muted)] hover:text-[var(--text)] transition-colors"
        >
          ← Back to Blog
        </a>

        <header className="mt-6">
          <div className="flex items-center gap-3">
            <StatusPill status={post.status} />
            <span className="text-xs text-[var(--muted)]">{post.publishedAt}</span>
          </div>
          <h1 className="mt-4 text-3xl sm:text-4xl font-semibold tracking-tight leading-tight">
            {post.title}
          </h1>
          <p className="mt-4 text-[var(--muted)]">{post.description}</p>
        </header>

        <article className="blog-prose mt-10">
          <Content />
        </article>

        <nav className="mt-14 grid gap-4 sm:grid-cols-2">
          <div className="rounded-xl border border-[var(--border)] bg-[var(--card2)] p-5">
            <p className="text-xs text-[var(--muted)]">Previous</p>
            {prev ? (
              <a
                href={`/blog/${prev.slug}`}
                className="mt-2 block font-medium hover:underline"
              >
                {prev.title}
              </a>
            ) : (
              <p className="mt-2 text-[var(--muted)]">—</p>
            )}
          </div>

          <div className="rounded-xl border border-[var(--border)] bg-[var(--card2)] p-5">
            <p className="text-xs text-[var(--muted)]">Next</p>
            {next ? (
              <a
                href={`/blog/${next.slug}`}
                className="mt-2 block font-medium hover:underline"
              >
                {next.title}
              </a>
            ) : (
              <p className="mt-2 text-[var(--muted)]">—</p>
            )}
          </div>
        </nav>
      </div>
    </Container>
  );
}

