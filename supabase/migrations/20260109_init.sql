-- MANUS 1.6 MAX - PostgreSQL Database Schema
-- Complete production-ready schema with RLS, vectors, and indexes

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgvector" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgtrgm" WITH SCHEMA extensions;

-- Create schema
CREATE SCHEMA IF NOT EXISTS manus;
GRANT USAGE ON SCHEMA manus TO public;

-- 1. AGENT TASKS TABLE
CREATE TABLE manus.agent_tasks (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'paused')),
  goal TEXT NOT NULL,
  context JSONB DEFAULT '{}',
  result JSONB,
  error TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER
);

CREATE INDEX idx_agent_tasks_user ON manus.agent_tasks(user_id);
CREATE INDEX idx_agent_tasks_status ON manus.agent_tasks(status);
CREATE INDEX idx_agent_tasks_created ON manus.agent_tasks(created_at DESC);

ALTER TABLE manus.agent_tasks ENABLE ROW LEVEL SECURITY;

-- 2. AGENT STEPS TABLE
CREATE TABLE manus.agent_steps (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES manus.agent_tasks(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  phase TEXT NOT NULL CHECK (phase IN ('analyze', 'plan', 'execute', 'observe')),
  action TEXT NOT NULL,
  input_data JSONB,
  output_data JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  error TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_agent_steps_task ON manus.agent_steps(task_id);
CREATE INDEX idx_agent_steps_phase ON manus.agent_steps(phase);
CREATE INDEX idx_agent_steps_status ON manus.agent_steps(status);

ALTER TABLE manus.agent_steps ENABLE ROW LEVEL SECURITY;

-- 3. MEMORY ITEMS TABLE (with vector embeddings)
CREATE TABLE manus.memory_items (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL,
  memory_type TEXT NOT NULL CHECK (memory_type IN ('fact', 'experience', 'decision', 'insight', 'pattern')),
  content TEXT NOT NULL,
  embedding extensions.vector(1536),
  metadata JSONB DEFAULT '{}',
  relevance_score FLOAT,
  access_count INTEGER DEFAULT 0,
  last_accessed TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_memory_items_user ON manus.memory_items(user_id);
CREATE INDEX idx_memory_items_type ON manus.memory_items(memory_type);
CREATE INDEX idx_memory_items_created ON manus.memory_items(created_at DESC);
CREATE INDEX idx_memory_embedding ON manus.memory_items USING ivfflat (embedding extensions.vector_cosine_ops) WITH (lists = 100);

ALTER TABLE manus.memory_items ENABLE ROW LEVEL SECURITY;

-- 4. NEWS CACHE TABLE
CREATE TABLE manus.news_cache (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  source TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  url TEXT,
  published_at TIMESTAMP WITH TIME ZONE,
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  fetch_method TEXT CHECK (fetch_method IN ('gpt_research', 'browser_use', 'playwright', 'crawl4ai', 'codeact')),
  metadata JSONB DEFAULT '{}',
  relevance_tags TEXT[],
  hash_digest TEXT UNIQUE NOT NULL,
  embedding extensions.vector(1536),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_news_cache_source ON manus.news_cache(source);
CREATE INDEX idx_news_cache_fetched ON manus.news_cache(fetched_at DESC);
CREATE INDEX idx_news_cache_published ON manus.news_cache(published_at DESC);
CREATE INDEX idx_news_cache_hash ON manus.news_cache(hash_digest);
CREATE INDEX idx_news_cache_tags ON manus.news_cache USING GIN(relevance_tags);

ALTER TABLE manus.news_cache ENABLE ROW LEVEL SECURITY;

-- 5. RESEARCH FINDINGS TABLE
CREATE TABLE manus.research_findings (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  task_id UUID REFERENCES manus.agent_tasks(id) ON DELETE SET NULL,
  user_id UUID NOT NULL,
  topic TEXT NOT NULL,
  agent_type TEXT CHECK (agent_type IN ('technical', 'market', 'data', 'philosophical', 'historical', 'risk')),
  finding TEXT NOT NULL,
  evidence JSONB,
  confidence_score FLOAT,
  sources TEXT[],
  consensus_status TEXT DEFAULT 'pending' CHECK (consensus_status IN ('pending', 'agreed', 'disputed', 'resolved')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_research_findings_task ON manus.research_findings(task_id);
CREATE INDEX idx_research_findings_user ON manus.research_findings(user_id);
CREATE INDEX idx_research_findings_topic ON manus.research_findings(topic);
CREATE INDEX idx_research_findings_agent ON manus.research_findings(agent_type);

ALTER TABLE manus.research_findings ENABLE ROW LEVEL SECURITY;

-- 6. USER SESSIONS TABLE
CREATE TABLE manus.user_sessions (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL,
  session_token TEXT UNIQUE NOT NULL,
  context JSONB DEFAULT '{}',
  active_task_id UUID REFERENCES manus.agent_tasks(id) ON DELETE SET NULL,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT now() + INTERVAL '7 days'
);

CREATE INDEX idx_user_sessions_user ON manus.user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON manus.user_sessions(session_token);
CREATE INDEX idx_user_sessions_activity ON manus.user_sessions(last_activity DESC);

ALTER TABLE manus.user_sessions ENABLE ROW LEVEL SECURITY;

-- 7. LLM LOGS TABLE
CREATE TABLE manus.llm_logs (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id UUID NOT NULL,
  task_id UUID REFERENCES manus.agent_tasks(id) ON DELETE SET NULL,
  provider TEXT NOT NULL CHECK (provider IN ('anthropic', 'openai', 'google', 'together', 'ollama')),
  model_name TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  response_text TEXT NOT NULL,
  tokens_used INTEGER,
  latency_ms INTEGER,
  cost_usd FLOAT,
  status TEXT DEFAULT 'success' CHECK (status IN ('success', 'error', 'timeout')),
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_llm_logs_user ON manus.llm_logs(user_id);
CREATE INDEX idx_llm_logs_task ON manus.llm_logs(task_id);
CREATE INDEX idx_llm_logs_provider ON manus.llm_logs(provider);
CREATE INDEX idx_llm_logs_model ON manus.llm_logs(model_name);
CREATE INDEX idx_llm_logs_created ON manus.llm_logs(created_at DESC);

ALTER TABLE manus.llm_logs ENABLE ROW LEVEL SECURITY;

-- ROW LEVEL SECURITY POLICIES

-- agent_tasks: Users can only see their own tasks
CREATE POLICY agent_tasks_select_policy ON manus.agent_tasks
  FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'service_role');

CREATE POLICY agent_tasks_insert_policy ON manus.agent_tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

CREATE POLICY agent_tasks_update_policy ON manus.agent_tasks
  FOR UPDATE USING (auth.uid() = user_id OR auth.role() = 'service_role');

CREATE POLICY agent_tasks_delete_policy ON manus.agent_tasks
  FOR DELETE USING (auth.uid() = user_id OR auth.role() = 'service_role');

-- memory_items: Users can only see their own memories
CREATE POLICY memory_items_select_policy ON manus.memory_items
  FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'service_role');

CREATE POLICY memory_items_insert_policy ON manus.memory_items
  FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

-- research_findings: Users can see their own research
CREATE POLICY research_findings_select_policy ON manus.research_findings
  FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'service_role');

-- VIEWS

-- Task summary view
CREATE VIEW manus.task_summary AS
SELECT 
  at.id,
  at.user_id,
  at.title,
  at.status,
  at.created_at,
  at.completed_at,
  at.duration_seconds,
  COUNT(DISTINCT CASE WHEN ast.status = 'completed' THEN ast.id END) as completed_steps,
  COUNT(DISTINCT ast.id) as total_steps
FROM manus.agent_tasks at
LEFT JOIN manus.agent_steps ast ON at.id = ast.task_id
GROUP BY at.id, at.user_id, at.title, at.status, at.created_at, at.completed_at, at.duration_seconds;

-- HELPER FUNCTIONS

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION manus.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to agent_tasks
CREATE TRIGGER agent_tasks_updated_at_trigger
  BEFORE UPDATE ON manus.agent_tasks
  FOR EACH ROW
  EXECUTE FUNCTION manus.update_updated_at_column();

-- Apply trigger to memory_items
CREATE TRIGGER memory_items_updated_at_trigger
  BEFORE UPDATE ON manus.memory_items
  FOR EACH ROW
  EXECUTE FUNCTION manus.update_updated_at_column();

-- Apply trigger to research_findings
CREATE TRIGGER research_findings_updated_at_trigger
  BEFORE UPDATE ON manus.research_findings
  FOR EACH ROW
  EXECUTE FUNCTION manus.update_updated_at_column();

-- Function for semantic search
CREATE OR REPLACE FUNCTION manus.search_memories(
  user_id_param UUID,
  search_embedding extensions.vector,
  limit_count INT DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  content TEXT,
  memory_type TEXT,
  similarity FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    mi.id,
    mi.content,
    mi.memory_type,
    (mi.embedding <-> search_embedding)::FLOAT as similarity
  FROM manus.memory_items mi
  WHERE mi.user_id = user_id_param AND mi.embedding IS NOT NULL
  ORDER BY mi.embedding <-> search_embedding
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Grants for public access through PostgREST
GRANT SELECT, INSERT, UPDATE ON manus.agent_tasks TO authenticated;
GRANT SELECT, INSERT, UPDATE ON manus.agent_steps TO authenticated;
GRANT SELECT, INSERT, UPDATE ON manus.memory_items TO authenticated;
GRANT SELECT ON manus.news_cache TO authenticated;
GRANT SELECT, INSERT ON manus.research_findings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON manus.user_sessions TO authenticated;
GRANT SELECT, INSERT ON manus.llm_logs TO authenticated;

GRANT EXECUTE ON FUNCTION manus.search_memories TO authenticated;
GRANT SELECT ON manus.task_summary TO authenticated;
