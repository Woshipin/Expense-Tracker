import { redirect } from 'next/navigation';

export default function Home() {
  // Always redirect default page to dashboard as requested
  redirect('/dashboard');
}
