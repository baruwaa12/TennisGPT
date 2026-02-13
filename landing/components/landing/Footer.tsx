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
          <a
            href="mailto:support@composure.app"
            className="text-sm text-[var(--muted)] hover:text-[var(--text)] transition-colors focus:outline-none focus:ring-2 focus:ring-[var(--blue)] rounded"
          >
            Support
          </a>
        </div>
      </Container>
    </footer>
  );
}
