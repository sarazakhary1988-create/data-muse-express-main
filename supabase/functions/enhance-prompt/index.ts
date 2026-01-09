import Anthropic from 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk@7.0.0/+esm';

interface PromptEnhancement {
  originalPrompt: string;
  context?: string;
  style?: 'detailed' | 'concise' | 'technical' | 'casual';
  includeExamples?: boolean;
  includeConstraints?: boolean;
}

interface EnhancedResult {
  originalPrompt: string;
  enhancedPrompt: string;
  improvements: string[];
  suggestions: string[];
}

const client = new Anthropic();

const enhancementPatterns = {
  detailed: 'Provide comprehensive step-by-step instructions with detailed context',
  concise: 'Provide clear, concise instructions without unnecessary details',
  technical: 'Use technical terminology and focus on precision',
  casual: 'Use conversational tone and accessible language',
};

async function enhancePrompt(enhancement: PromptEnhancement): Promise<EnhancedResult> {
  const styleGuide = enhancement.style ? enhancementPatterns[enhancement.style] : '';
  
  const systemPrompt = `You are an expert prompt engineer. Your task is to enhance and improve prompts.
${styleGuide}
${enhancement.includeExamples ? '\nInclude examples in the enhanced prompt.' : ''}
${enhancement.includeConstraints ? '\nInclude clear constraints and limitations.' : ''}`;

  const message = await client.messages.create({
    model: 'claude-3-5-sonnet-20241022',
    max_tokens: 2048,
    system: systemPrompt,
    messages: [
      {
        role: 'user',
        content: `Please enhance this prompt:"${enhancement.originalPrompt}"${enhancement.context ? `\nContext: ${enhancement.context}` : ''}\n\nProvide your response in this JSON format:
{
  "enhancedPrompt": "the improved prompt",
  "improvements": ["list", "of", "improvements"],
  "suggestions": ["additional", "suggestions"]
}`,
      },
    ],
  });

  const content = message.content[0];
  const result = content.type === 'text' ? JSON.parse(content.text) : {};
  
  return {
    originalPrompt: enhancement.originalPrompt,
    enhancedPrompt: result.enhancedPrompt || '',
    improvements: result.improvements || [],
    suggestions: result.suggestions || [],
  };
}

async function handleEnhancePrompt(req: Request): Promise<Response> {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const enhancement: PromptEnhancement = await req.json();
    const result = await enhancePrompt(enhancement);

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

Export { handleEnhancePrompt as default };