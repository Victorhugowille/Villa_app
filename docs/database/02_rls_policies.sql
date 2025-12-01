-- Habilitar RLS (Row Level Security) nas tabelas principais
ALTER TABLE public.mesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- POLÍTICA: Ver dados apenas da própria empresa
-- Supondo que o usuário logado tenha o 'company_id' nos metadados ou tabela de perfil

-- 1. Leitura de Mesas (Garçons e Cozinha)
CREATE POLICY "Ver mesas da minha empresa"
ON public.mesas
FOR SELECT
USING (
  auth.uid() IN (
    SELECT user_id FROM public.profiles 
    WHERE company_id = mesas.company_id
  )
);

-- 2. Inserção de Pedidos (Garçons)
CREATE POLICY "Criar pedidos na minha empresa"
ON public.pedidos
FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT user_id FROM public.profiles 
    WHERE company_id = pedidos.company_id
  )
);