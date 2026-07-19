import '@fontsource/cairo/400.css';
import '@fontsource/cairo/600.css';
import '@fontsource/cairo/700.css';
import './globals.css';
import type { Metadata } from 'next';
import { PlatformShell } from '@/components/platform-shell';

export const metadata: Metadata = { title: 'هنا قنا', description: 'كل ما تحتاجه.. قريب منك' };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ar" dir="rtl" data-scroll-behavior="smooth" suppressHydrationWarning><body><PlatformShell>{children}</PlatformShell></body></html>;
}
