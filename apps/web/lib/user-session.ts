import 'server-only';

import { cookies } from 'next/headers';

const tokenCookie = 'henaqena_user_api_token';
const maxAge = 30 * 24 * 60 * 60;

export async function createUserSession(token: string) {
  const store = await cookies();
  store.set(tokenCookie, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge,
  });
}

export async function getUserApiToken() {
  return (await cookies()).get(tokenCookie)?.value ?? null;
}

export async function clearUserSession() {
  (await cookies()).delete(tokenCookie);
}
