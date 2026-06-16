import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['var(--font-plus-jakarta-sans)', 'var(--font-inter)', 'sans-serif'],
      },
      colors: {
        'sunset-bg': '#FCF8F3',
        'sunset-primary': '#FF7B42',
        'sunset-secondary': '#FF6231',
        'sunset-dark': '#2D1B14',
        'sunset-success': '#4CAF50',
        'sunset-error': '#F44336',
      },
    },
  },
  plugins: [],
};
export default config;
