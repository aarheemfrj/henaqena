'use client';

import { useState, useTransition } from 'react';

export function FavoriteButton({ id, kind }: { id: string; kind: 'providers' | 'listings' }) {
  const [active, setActive] = useState(false);
  const [pending, startTransition] = useTransition();
  return <button
    type="button"
    className="cardFavorite"
    aria-label="أضف للمفضلة"
    disabled={pending}
    onClick={(event) => {
      event.preventDefault();
      event.stopPropagation();
      startTransition(async () => {
        const response = await fetch(`/api/favorites/${kind}/${id}`, { method: 'POST' });
        if (response.status === 401) { window.location.href = '/account'; return; }
        if (response.ok) { const body = await response.json() as { active: boolean }; setActive(body.active); }
      });
    }}
  >{active ? '★' : '☆'}</button>;
}
