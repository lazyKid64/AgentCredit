import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Link from 'next/link';

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AgentCredit Dashboard",
  description: "On-chain credit bureau for AI agents",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-gray-950 text-gray-100 min-h-screen flex flex-col`}>
        <nav className="border-b border-gray-800 bg-gray-900/50 backdrop-blur-md sticky top-0 z-10">
          <div className="max-w-5xl mx-auto px-6 py-4 flex justify-between items-center">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center font-bold text-white shadow-[0_0_15px_rgba(59,130,246,0.5)]">
                AC
              </div>
              <span className="font-bold tracking-tight text-xl text-gray-100">AgentCredit</span>
            </div>
            <div className="flex gap-6">
              <Link href="/" className="text-sm font-medium text-gray-400 hover:text-white transition-colors">
                Score Lookup
              </Link>
              <Link href="/prove" className="text-sm font-medium text-gray-400 hover:text-white transition-colors">
                Generate Proof
              </Link>
            </div>
          </div>
        </nav>
        <div className="flex-grow">
          {children}
        </div>
      </body>
    </html>
  );
}
