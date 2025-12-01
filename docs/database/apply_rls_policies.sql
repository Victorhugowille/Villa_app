-- ============================================================
-- 1. Habilitar RLS (Row Level Security) em todas as tabelas
-- Isso bloqueia todo o acesso externo por padrão.
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itens_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. Criar Políticas de Acesso (Policies)
-- A lógica é: "Permitir se o company_id da linha for igual ao meu company_id"
-- ============================================================

-- ------------------------------------------------------------
-- Tabela: PROFILES (Perfis de Usuário)
-- ------------------------------------------------------------
-- Usuários podem ver seus próprios perfis e perfis de colegas da mesma empresa
CREATE POLICY "Ver perfis da mesma empresa" ON public.profiles
FOR SELECT USING (
  company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

-- Usuários só podem atualizar seus próprios dados
CREATE POLICY "Atualizar próprio perfil" ON public.profiles
FOR UPDATE USING (
  auth.uid() = user_id
);

-- ------------------------------------------------------------
-- Tabela: MESAS
-- ------------------------------------------------------------
CREATE POLICY "Acesso total a mesas da minha empresa" ON public.mesas
FOR ALL USING (
  company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

-- ------------------------------------------------------------
-- Tabela: PEDIDOS
-- ------------------------------------------------------------
CREATE POLICY "Acesso total a pedidos da minha empresa" ON public.pedidos
FOR ALL USING (
  company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

-- ------------------------------------------------------------
-- Tabela: ITENS_PEDIDO
-- (Assume que esta tabela não tem company_id direto, então checa via pedido)
-- SE TIVER company_id, use a lógica simples das mesas.
-- ------------------------------------------------------------
CREATE POLICY "Acesso a itens via pedido da empresa" ON public.itens_pedido
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.pedidos p
    WHERE p.id = itens_pedido.pedido_id
    AND p.company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
  )
);

-- ------------------------------------------------------------
-- Tabela: PRODUTOS & CATEGORIAS
-- ------------------------------------------------------------
CREATE POLICY "Ver produtos da empresa" ON public.produtos
FOR ALL USING (
  company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

CREATE POLICY "Ver categorias da empresa" ON public.categorias
FOR ALL USING (
  company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

-- ------------------------------------------------------------
-- Tabela: TRANSACOES
-- ------------------------------------------------------------
CREATE POLICY "Ver transacoes da empresa" ON public.transacoes
FOR ALL USING (
  company_id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

-- ------------------------------------------------------------
-- Tabela: COMPANY (Dados da Empresa)
-- ------------------------------------------------------------
CREATE POLICY "Ver dados da minha empresa" ON public.company
FOR SELECT USING (
  id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid())
);

-- Apenas Admin/Dono pode atualizar dados da empresa (Exemplo de regra extra)
-- CREATE POLICY "Admin atualiza empresa" ON public.company
-- FOR UPDATE USING (
--   id = (SELECT company_id FROM public.profiles WHERE user_id = auth.uid() AND role = 'admin')
-- );