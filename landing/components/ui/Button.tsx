import { ButtonHTMLAttributes, ReactNode } from "react";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: "primary" | "secondary" | "ghost";
  className?: string;
}

export function Button({
  children,
  variant = "primary",
  className = "",
  ...props
}: ButtonProps) {
  const base =
    "inline-flex items-center justify-center rounded-xl font-semibold tracking-[0.01em] transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-[var(--blueGlow)] focus:ring-offset-2 focus:ring-offset-[var(--bg)] disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.99]";

  const variants = {
    primary:
      "bg-[var(--blue)] text-[var(--bg)] hover:brightness-110 hover:shadow-glow px-6 py-3",
    secondary:
      "bg-[var(--card2)] text-[var(--text)] border border-[var(--border)] hover:border-[var(--blue)]/60 hover:bg-[var(--card)] px-6 py-3",
    ghost:
      "text-[var(--text)] hover:bg-[var(--card2)] px-6 py-3",
  };

  return (
    <button
      className={`${base} ${variants[variant]} ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}
