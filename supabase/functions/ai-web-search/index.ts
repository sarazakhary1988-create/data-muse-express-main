import Anthropic from 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk@7.0.0/+esm';

interface SearchParams {
  query: string;
  maxResults?: number;
  searchEngine?: 'google' | 'bing' | 'duckduckgo';
  aiEnhance?: boolean;
}

const client = new Anthropic();

async function performSearch(query: string, engine: string): Promise<any[]> {
  // Use appropriate search engine API
  const url = new URL('https://api.search.brave.com/res/v1/web/search');
  url.searchParams.set('q', query);
  url.searchParams.set('count', '10');

  const response = await fetch(url.toString(), {
    headers: {
      'X-Subscription-Token': Deno.env.get('BRAVE_API_KEY') || '',
      'Accept': 'application/json',
    },
  });

  const data = await response.json();
  return data.results || [];
}

async function enhanceSearchResults(query: string, results: any[]): Promise<any> {
  const message = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 2048,
    messages: [
      {
        role: 'user',
        content: `Analyze these search results for the query "${query}" and provide insights:\n${JSON.stringify(results, null, 2)}`,
      },
    ],
  });

  const content = message.content[0];
  return content.type === 'text' ? content.text : null;
}

async function handleAiWebSearch(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const params: SearchParams = await req.json();
    const { query, maxResults = 10, searchEngine = 'google', aiEnhance = false } = params;

    const results = await performSearch(query, searchEngine);
    const limited = results.slice(0, maxResults);

    let enhancement = null;
    if (aiEnhance) {
      enhancement = await enhanceSearchResults(query, limited);
    }

    return new Response(
      JSON.stringify({
        success: true,
        query,
        results: limited,
        enhancement,
        timestamp: new Date().toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

Export { handleAiWebSearch as default };