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
    "inline-flex items-center justify-center rounded-lg font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-[var(--blue)] focus:ring-offset-2 focus:ring-offset-[var(--bg)] disabled:opacity-50 disabled:cursor-not-allowed";

  const variants = {
    primary:
      "bg-[var(--blue)] text-white hover:shadow-glow hover:shadow-[var(--blueGlow)]/30 px-6 py-3",
    secondary:
      "bg-[var(--card)] text-[var(--text)] border border-[var(--border)] hover:border-[var(--blue)]/50 px-6 py-3",
    ghost:
      "text-[var(--text)] hover:bg-white/5 px-6 py-3",
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
