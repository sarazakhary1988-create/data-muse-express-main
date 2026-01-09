import Anthropic from 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk@7.0.0/+esm';
import { parse } from 'https://cdn.jsdelivr.net/npm/csv-parse@5.4.1/+esm';
import { stringify } from 'https://cdn.jsdelivr.net/npm/csv-stringify@6.4.6/+esm';

interface ScrapeCommand {
  url: string;
  selectors: string[];
  returnFormat: 'json' | 'csv' | 'text';
  waitForSelector?: string;
  timeout?: number;
  aiEnhance?: boolean;
}

interface ScrapeResult {
  url: string;
  data: Record<string, any>[];
  timestamp: string;
  success: boolean;
  error?: string;
}

const client = new Anthropic();

async function scrapeWithAI(html: string, instructions: string): Promise<any> {
  const message = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 4096,
    messages: [
      {
        role: 'user',
        content: `Extract and parse the following HTML according to these instructions: ${instructions}\n\nHTML:\n${html}\n\nReturn the extracted data as valid JSON.`,
      },
    ],
  });

  const content = message.content[0];
  if (content.type === 'text') {
    try {
      return JSON.parse(content.text);
    } catch {
      return { raw: content.text };
    }
  }
  return null;
}

async function handleAiScrapeCommand(
  req: Request
): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const command: ScrapeCommand = await req.json();
    const { url, selectors, returnFormat, aiEnhance } = command;

    // Fetch the page
    const pageResponse = await fetch(url);
    if (!pageResponse.ok) {
      throw new Error(`Failed to fetch ${url}: ${pageResponse.statusText}`);
    }

    const html = await pageResponse.text();
    const dom = new DOMParser().parseFromString(html, 'text/html');

    const results: Record<string, any>[] = [];

    // Extract using selectors
    for (const selector of selectors) {
      const elements = dom.querySelectorAll(selector);
      for (const el of elements) {
        const data: Record<string, any> = {
          selector,
          text: el.textContent?.trim() || '',
          html: el.outerHTML,
        };

        if (aiEnhance) {
          const enhanced = await scrapeWithAI(el.outerHTML, `Extract structured data from this element`);
          data.aiEnhanced = enhanced;
        }

        results.push(data);
      }
    }

    const response: ScrapeResult = {
      url,
      data: results,
      timestamp: new Date().toISOString(),
      success: true,
    };

    // Format output
    let output: string;
    if (returnFormat === 'json') {
      output = JSON.stringify(response, null, 2);
    } else if (returnFormat === 'csv') {
      output = await stringifyAsync(results);
    } else {
      output = results.map((r) => r.text).join('\n');
    }

    return new Response(output, {
      headers: { 'Content-Type': `application/${returnFormat === 'csv' ? 'csv' : 'json'}` },
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

function stringifyAsync(data: any[]): Promise<string> {
  return new Promise((resolve, reject) => {
    stringify(data, (err: any, output: string) => {
      if (err) reject(err);
      else resolve(output);
    });
  });
}

Export { handleAiScrapeCommand as default };