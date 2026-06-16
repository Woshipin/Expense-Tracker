import "@/app/globals.css";
import React from "react";
import SidebarLayout from "@/components/SidebarLayout";
import { Plus_Jakarta_Sans, Inter } from "next/font/google";

const plusJakartaSans = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-plus-jakarta-sans",
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata = {
  title: "Sunset Expense Tracker",
  description: "A beautiful expense tracker",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    // suppressHydrationWarning added to html and body to fix browser translation extension errors
    <html lang="en" suppressHydrationWarning className={`${plusJakartaSans.variable} ${inter.variable}`}>
      <body suppressHydrationWarning className="font-sans antialiased text-sunset-dark">
        <SidebarLayout>{children}</SidebarLayout>
      </body>
    </html>
  );
}
