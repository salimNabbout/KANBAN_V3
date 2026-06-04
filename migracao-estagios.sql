-- ============================================================
-- MIGRAÇÃO DE ESTÁGIOS — CRM CETEM  →  Kanban de Tarefas
-- Renomeia as 4 etapas no banco E remapeia todos os cards.
--
-- Mapeamento:
--   Lead              -> A fazer
--   Contato feito     -> Fazendo
--   Qualificação      -> Em espera
--   Reunião Agendada  -> Concluído
--
-- COMO USAR:
--   1. Supabase -> SQL Editor -> New query
--   2. Rode primeiro a SEÇÃO 1 (diagnóstico). Confira se os nomes
--      antigos que aparecem batem com os do mapeamento abaixo.
--      Se aparecer algum nome diferente, me avise antes de migrar.
--   3. Rode a SEÇÃO 2 (migração). Ela está dentro de uma transação:
--      confira o resultado do SELECT final e só então faça COMMIT.
--      Se algo estiver errado, rode ROLLBACK.
-- ============================================================


-- ============================================================
-- SEÇÃO 1 — DIAGNÓSTICO (apenas leitura, rode primeiro)
-- ============================================================

-- 1a. Quais valores de etapa existem hoje nos cards e quantos cards em cada:
SELECT stage AS etapa_atual, count(*) AS qtd
FROM prospects
GROUP BY stage
ORDER BY qtd DESC;

-- 1b. Como estão salvas as etapas na configuração global:
SELECT value AS stages_config
FROM crm_config
WHERE key = 'stages';


-- ============================================================
-- SEÇÃO 2 — MIGRAÇÃO (transacional)
-- Selecione e rode deste BEGIN até o COMMIT.
-- ============================================================
BEGIN;

-- 2a. Remapeia o estágio de todos os cards (case-insensitive, tolera espaços)
UPDATE prospects
SET stage = CASE
  WHEN lower(trim(stage)) = 'lead'             THEN 'A fazer'
  WHEN lower(trim(stage)) = 'contato feito'    THEN 'Fazendo'
  WHEN lower(trim(stage)) = 'qualificação'     THEN 'Em espera'
  WHEN lower(trim(stage)) = 'reunião agendada' THEN 'Concluído'
  ELSE stage
END
WHERE lower(trim(stage)) IN ('lead','contato feito','qualificação','reunião agendada');

-- 2b. Renomeia name + short dentro do JSON de configuração,
--     preservando cor, descrição e ordem de cada etapa.
UPDATE crm_config
SET value = (
  SELECT jsonb_agg(
    CASE
      WHEN lower(trim(elem->>'name')) = 'lead'
        THEN jsonb_set(jsonb_set(elem, '{name}', '"A fazer"'),   '{short}', '"A fazer"')
      WHEN lower(trim(elem->>'name')) = 'contato feito'
        THEN jsonb_set(jsonb_set(elem, '{name}', '"Fazendo"'),   '{short}', '"Fazendo"')
      WHEN lower(trim(elem->>'name')) = 'qualificação'
        THEN jsonb_set(jsonb_set(elem, '{name}', '"Em espera"'), '{short}', '"Em espera"')
      WHEN lower(trim(elem->>'name')) = 'reunião agendada'
        THEN jsonb_set(jsonb_set(elem, '{name}', '"Concluído"'), '{short}', '"Concluído"')
      ELSE elem
    END
    ORDER BY ord.idx
  )
  FROM jsonb_array_elements(value) WITH ORDINALITY AS ord(elem, idx)
),
updated_at = now()
WHERE key = 'stages';

-- 2c. VERIFICAÇÃO — confira o resultado antes de confirmar
SELECT stage AS etapa_nova, count(*) AS qtd FROM prospects GROUP BY stage ORDER BY qtd DESC;
SELECT value AS stages_config_novo FROM crm_config WHERE key = 'stages';

-- Se estiver tudo certo:
COMMIT;
-- Se algo estiver errado, troque o COMMIT acima por:
-- ROLLBACK;
