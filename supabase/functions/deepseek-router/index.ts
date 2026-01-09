import Anthropic from 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk@7.0.0/+esm';

interface RoutingRequest {
  query: string;
  context?: string;
  preferredModels?: string[];
  complexity?: 'low' | 'medium' | 'high';
}

interface RoutingResult {
  route: string;
  model: string;
  reasoning: string;
  cost_estimate?: number;
}

const client = new Anthropic();

const modelCapabilities: Record<string, string[]> = {
  'claude-3-5-sonnet-20241022': ['general', 'code', 'analysis', 'research'],
  'claude-opus': ['complex-reasoning', 'code', 'analysis'],
  'claude-haiku': ['simple', 'fast-responses'],
};

async function determineRoute(request: RoutingRequest): Promise<RoutingResult> {
  const message = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 512,
    messages: [
      {
        role: 'user',
        content: `Analyze this request and determine the best model to route it to:\n${JSON.stringify(request, null, 2)}\n\nConsider:\n- Query complexity\n- Context requirements\n- Cost efficiency\n- Task type\n\nRespond with JSON: {route, model, reasoning}`,
      },
    ],
  });

  const content = message.content[0];
  const result = content.type === 'text' ? JSON.parse(content.text) : {};
  return result;
}

async function handleDeepseekRouter(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const request: RoutingRequest = await req.json();
    const result = await determineRoute(request);

    return new Response(JSON.stringify({ success: true, ...result }), {
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

Export { handleDeepseekRouter as default };