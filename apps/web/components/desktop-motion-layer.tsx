'use client';

import { useEffect } from 'react';

export function DesktopMotionLayer() {
  useEffect(() => {
    const canAnimate = window.matchMedia('(min-width: 851px) and (hover: hover) and (pointer: fine)');
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    let frame = 0;

    function handlePointerMove(event: PointerEvent) {
      if (!canAnimate.matches || reduceMotion.matches) return;
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        document.documentElement.style.setProperty('--pointer-x', `${event.clientX}px`);
        document.documentElement.style.setProperty('--pointer-y', `${event.clientY}px`);
      });
    }

    window.addEventListener('pointermove', handlePointerMove, { passive: true });
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener('pointermove', handlePointerMove);
    };
  }, []);

  return <div className="desktopPointerGlow" aria-hidden="true" />;
}
