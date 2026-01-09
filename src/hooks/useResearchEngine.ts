import { useEffect, useState } from 'react';

export function useResearchEngine(topic: string) {
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);

  const research = async () => {
    setLoading(true);
    // Execute research
    setLoading(false);
  };

  return { results, loading, research };
}
