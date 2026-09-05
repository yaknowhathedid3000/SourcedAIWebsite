import type { Config } from "tailwindcss";

// Tokens mirror ios/Albo/Albo/DesignSystem/AlboColor.swift (teardown 3.2).
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#1C1C1E",
        ink2: "#595959",
        muted: "#8C8C8C",
        surface: "#F4F4F4",
        option: "#EFEFEF",
        hairline: "#E6E6E6",
        blue: "#0A7AFF",
        reward: "#22C55E",
        rewardDeep: "#16A34A",
        danger: "#D6203A",
        brand: "#F5891F",
        rating: "#FFF4CC",
        star: "#F5B800",
      },
      fontFamily: {
        serif: ['"Source Serif 4"', '"New York"', "Georgia", "serif"],
        sans: ['"Instrument Sans"', "-apple-system", "BlinkMacSystemFont", '"SF Pro Text"', "Inter", "sans-serif"],
      },
      borderRadius: { pill: "999px", card: "20px", sheet: "28px" },
      boxShadow: {
        card: "0 6px 14px rgba(0,0,0,0.06)",
        hard: "0 5px 0 #000",
        hardDanger: "0 5px 0 #8E1526",
      },
      keyframes: {
        orbit: { from: { transform: "rotate(0deg)" }, to: { transform: "rotate(360deg)" } },
        orbitReverse: { from: { transform: "rotate(360deg)" }, to: { transform: "rotate(0deg)" } },
        rise: { from: { opacity: "0", transform: "translateY(12px)" }, to: { opacity: "1", transform: "translateY(0)" } },
      },
      animation: {
        orbit: "orbit 28s linear infinite",
        orbitReverse: "orbitReverse 40s linear infinite",
        rise: "rise .35s ease-out both",
      },
    },
  },
  plugins: [],
};

export default config;
