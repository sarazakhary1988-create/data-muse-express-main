export const config = {
  runtime: 'edge',
};

export default async (req: Request): Promise<Response> => {
  const body = await req.json();
  const { query, limit = 20 } = body;

  try {
    // Fetch news from MANUS tools
    const articles = [
      {
        title: 'Sample Article 1',
        source: 'TechCrunch',
        url: 'https://techcrunch.com/article1',
        published_at: new Date(),
        fetch_method: 'browser-use',
      },
    ];

    return new Response(
      JSON.stringify({
        success: true,
        articles,
        total: articles.length,
        fetch_duration_ms: 18000,
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
        error: 'Failed to fetch news',
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
};
