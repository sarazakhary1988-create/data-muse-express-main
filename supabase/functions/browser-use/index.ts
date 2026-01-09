import Anthropic from 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk@7.0.0/+esm';

interface BrowserAction {
  type: 'navigate' | 'click' | 'type' | 'scroll' | 'wait' | 'screenshot' | 'extract';
  selector?: string;
  text?: string;
  url?: string;
  delay?: number;
}

interface BrowserSession {
  sessionId: string;
  url: string;
  actions: BrowserAction[];
  timeout?: number;
}

const client = new Anthropic();
const browserSessions = new Map<string, any>();

async function executeBrowserAction(action: BrowserAction, context: string): Promise<any> {
  const message = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 1024,
    messages: [
      {
        role: 'user',
        content: `Execute this browser action in context of: ${context}\nAction: ${JSON.stringify(action)}`,
      },
    ],
  });

  const content = message.content[0];
  return content.type === 'text' ? content.text : null;
}

async function handleBrowserUse(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const session: BrowserSession = await req.json();
    const { sessionId, url, actions, timeout = 30000 } = session;

    let sessionData = browserSessions.get(sessionId) || { url, results: [] };

    for (const action of actions) {
      const result = await executeBrowserAction(action, url);
      sessionData.results.push({
        action: action.type,
        result,
        timestamp: new Date().toISOString(),
      });
    }

    browserSessions.set(sessionId, sessionData);

    return new Response(
      JSON.stringify({
        success: true,
        sessionId,
        results: sessionData.results,
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

Export { handleBrowserUse as default };