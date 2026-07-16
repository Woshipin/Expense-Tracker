import "@/app/globals.css";
import React from "react";
import SidebarLayout from "@/components/SidebarLayout";

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
    <html lang="en" suppressHydrationWarning>
      <body suppressHydrationWarning className="antialiased text-sunset-dark">
        <SidebarLayout>{children}</SidebarLayout>
      </body>
    </html>
  );
}