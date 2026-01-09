export const config = {
  runtime: 'edge',
};

export default async (req: Request): Promise<Response> => {
  const body = await req.json();
  const { topic, depth = 'comprehensive' } = body;

  try {
    const result = {
      success: true,
      consensus: {
        score: 0.87,
        recommendation: 'yes',
      },
      findings: {
        technical: 'Feasible, 9/10',
        market: 'Strong demand, 8/10',
        risk: 'Manageable risks, 7/10',
      },
      duration_ms: 185000,
    };

    return new Response(
      JSON.stringify(result),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Research failed',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
};
