import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        bg: "var(--bg)",
        bg2: "var(--bg2)",
        card: "var(--card)",
        card2: "var(--card2)",
        border: "var(--border)",
        muted: "var(--muted)",
        blue: "var(--blue)",
        blueGlow: "var(--blueGlow)",
        accent2: "var(--accent2)",
        success: "var(--success)",
        warning: "var(--warning)",
        error: "var(--error)",
      },
      boxShadow: {
        glow: "0 0 20px rgba(125, 194, 255, 0.24)",
        "glow-sm": "0 0 12px rgba(125, 194, 255, 0.18)",
      },
    },
  },
  plugins: [],
};
export default config;
