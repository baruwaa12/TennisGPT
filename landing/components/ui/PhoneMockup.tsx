"use client";

import { useState } from "react";
import Image from "next/image";

interface PhoneMockupProps {
  src: string;
  alt: string;
  className?: string;
}

export function PhoneMockup({ src, alt, className = "" }: PhoneMockupProps) {
  const [errored, setErrored] = useState(false);
  const filename = src.split("/").pop() ?? src;

  return (
    <div
      className={`relative mx-auto w-[280px] sm:w-[320px] rounded-[2.5rem] border-[10px] border-[var(--card2)] bg-[var(--card2)] p-2 shadow-2xl ${className}`}
    >
      <div className="overflow-hidden rounded-[1.75rem] bg-black aspect-[9/19] relative">
        {errored ? (
          <div className="flex h-full w-full items-center justify-center bg-[var(--card)] text-[var(--muted)] text-sm p-4 text-center">
            {filename}
          </div>
        ) : (
          <Image
            src={src}
            alt={alt}
            fill
            className="object-cover object-top"
            sizes="(max-width: 640px) 280px, 320px"
            onError={() => setErrored(true)}
          />
        )}
      </div>
    </div>
  );
}
