export const config = {
  runtime: 'edge',
};

export default async (req: Request): Promise<Response> => {
  const body = await req.json();
  const { action, query, limit = 10 } = body;

  try {
    if (action === 'search') {
      const memories = [
        {
          id: 'mem_001',
          content: 'Enterprise AI adoption growing 45% YoY',
          similarity: 0.92,
        },
      ];

      return new Response(
        JSON.stringify({
          success: true,
          memories,
        }),
        {
          headers: { 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Memory operation failed',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
};
