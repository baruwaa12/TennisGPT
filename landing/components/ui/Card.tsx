import { ReactNode } from "react";

interface CardProps {
  children: ReactNode;
  className?: string;
}

export function Card({ children, className = "" }: CardProps) {
  return (
    <div
      className={`rounded-xl border border-[var(--border)] bg-[var(--card)] p-6 backdrop-blur-sm ${className}`}
    >
      {children}
    </div>
  );
}
