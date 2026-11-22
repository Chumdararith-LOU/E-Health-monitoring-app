// Tiny hash router (no extra package). Routes:
//   #/login · #/doctor · #/doctor/patient/:id · #/admin/users · #/admin/fields

import { useEffect, useState } from 'react';

export function navigate(path: string) {
  if (window.location.hash !== `#${path}`) window.location.hash = path;
}

export function useRoute(): string[] {
  const read = () => window.location.hash.replace(/^#\/?/, '').split('/').filter(Boolean);
  const [parts, setParts] = useState<string[]>(read);
  useEffect(() => {
    const on = () => {
      setParts(read());
      window.scrollTo(0, 0);
    };
    window.addEventListener('hashchange', on);
    return () => window.removeEventListener('hashchange', on);
  }, []);
  return parts;
}
