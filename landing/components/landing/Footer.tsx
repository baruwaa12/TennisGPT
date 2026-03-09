import { Container } from "@/components/ui/Container";

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="py-8 border-t border-[var(--border)]">
      <Container>
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-[var(--muted)]">
            © {year} Composure. All rights reserved.
          </p>
          <div className="flex items-center gap-4">
            <a
              href="/blog"
              className="text-sm text-[var(--muted)] hover:text-[var(--text)] transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--blue)] rounded"
            >
              Blog
            </a>
            <a
              href="/app/"
              className="text-sm text-[var(--muted)] hover:text-[var(--text)] transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--blue)] rounded"
            >
              Open App
            </a>
            <a
              href="/support"
              className="text-sm text-[var(--muted)] hover:text-[var(--text)] transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--blue)] rounded"
            >
              Support
            </a>
          </div>
        </div>
      </Container>
    </footer>
  );
}
