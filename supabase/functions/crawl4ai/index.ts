import Anthropic from 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk@7.0.0/+esm';

interface CrawlConfig {
  url: string;
  depth?: number;
  maxPages?: number;
  followExternalLinks?: boolean;
  extractContent?: boolean;
  aiAnalysis?: boolean;
}

interface CrawlResult {
  url: string;
  status: number;
  content?: string;
  links: string[];
  analysis?: string;
  timestamp: string;
}

const client = new Anthropic();
const crawledUrls = new Set<string>();

async function analyzeContent(content: string, url: string): Promise<string> {
  const message = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content: `Analyze the content from ${url} and provide key insights:\n${content.substring(0, 5000)}`,
      },
    ],
  });

  const content_response = message.content[0];
  return content_response.type === 'text' ? content_response.text : '';
}

async function crawlPage(url: string, config: CrawlConfig, depth: number = 0): Promise<CrawlResult[]> {
  if (depth > (config.depth || 2) || crawledUrls.has(url) || crawledUrls.size >= (config.maxPages || 50)) {
    return [];
  }

  crawledUrls.add(url);

  try {
    const response = await fetch(url);
    const html = await response.text();

    let analysis = undefined;
    if (config.aiAnalysis) {
      analysis = await analyzeContent(html, url);
    }

    const dom = new DOMParser().parseFromString(html, 'text/html');
    const links = Array.from(dom.querySelectorAll('a[href]'))
      .map((a) => (a as HTMLAnchorElement).href)
      .filter((href) => config.followExternalLinks || href.startsWith(new URL(url).origin))
      .slice(0, 10);

    const result: CrawlResult = {
      url,
      status: response.status,
      content: config.extractContent ? html.substring(0, 10000) : undefined,
      links,
      analysis,
      timestamp: new Date().toISOString(),
    };

    const results = [result];

    for (const link of links) {
      const childResults = await crawlPage(link, config, depth + 1);
      results.push(...childResults);
    }

    return results;
  } catch (error) {
    return [
      {
        url,
        status: 500,
        links: [],
        timestamp: new Date().toISOString(),
      },
    ];
  }
}

async function handleCrawl4AI(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const config: CrawlConfig = await req.json();
    crawledUrls.clear();

    const results = await crawlPage(config.url, config);

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { 'Content-Type': 'application/json' },
    });
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

Export { handleCrawl4AI as default };