import { useEffect, useState } from 'react';

export function useNewsMonitor(topic: string) {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const monitor = async () => {
      setLoading(true);
      // Fetch news
      setLoading(false);
    };

    monitor();
  }, [topic]);

  return { articles, loading };
}
