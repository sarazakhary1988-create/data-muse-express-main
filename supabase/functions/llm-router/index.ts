export const config = {
  runtime: 'edge',
};

export default async (req: Request): Promise<Response> => {
  const body = await req.json();
  const { prompt, model = 'auto' } = body;

  try {
    // Route to appropriate LLM
    const response = `Response from ${model}`;

    return new Response(
      JSON.stringify({
        success: true,
        response,
        model,
        tokens: 150,
        latency_ms: 1200,
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Request failed',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
};
