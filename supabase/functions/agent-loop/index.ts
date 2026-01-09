export const config = {
  runtime: 'edge',
};

export default async (req: Request): Promise<Response> => {
  const body = await req.json();
  const { goal, max_iterations = 5 } = body;

  try {
    const result = {
      success: true,
      goal,
      iterations: 3,
      status: 'completed',
      result: { plan: 'Business plan generated' },
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
        error: 'Agent loop failed',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
};
