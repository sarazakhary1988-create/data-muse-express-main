import { useEffect, useState } from 'react';

export function useManusRealtime(query: string) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      setLoading(true);
      // Fetch from MANUS
      setLoading(false);
    };

    fetch();
  }, [query]);

  return { data, loading };
}
