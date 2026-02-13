import { Hero } from "@/components/landing/Hero";
import { Problem } from "@/components/landing/Problem";
import { Pillars } from "@/components/landing/Pillars";
import { Showcase } from "@/components/landing/Showcase";
import { Pricing } from "@/components/landing/Pricing";
import { FounderAccess } from "@/components/landing/FounderAccess";
import { FAQ } from "@/components/landing/FAQ";
import { FinalCTA } from "@/components/landing/FinalCTA";

export default function Home() {
  return (
    <>
      <Hero />
      <Problem />
      <Pillars />
      <Showcase />
      <Pricing />
      <FounderAccess />
      <FAQ />
      <FinalCTA />
    </>
  );
}
