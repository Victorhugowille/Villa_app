-- ============================================================
-- TRIGGER: Sincronização Automática de Status da Mesa
-- Objetivo: Se houver pedidos abertos, a mesa vira 'ocupada'.
--           Se todos os pedidos forem finalizados, vira 'livre'.
-- ============================================================

-- 1. Criar a função que faz a contagem e atualização
CREATE OR REPLACE FUNCTION public.sync_table_status()
RETURNS TRIGGER AS $$
DECLARE
  target_table_id BIGINT;
  active_orders_count INT;
BEGIN
  -- Identifica qual mesa foi afetada (seja por novo pedido, atualização ou exclusão)
  target_table_id := COALESCE(NEW.mesa_id, OLD.mesa_id);

  -- Conta quantos pedidos ativos (não finalizados) existem para essa mesa
  SELECT count(*) INTO active_orders_count
  FROM public.pedidos
  WHERE mesa_id = target_table_id
  AND status NOT IN ('finalizado', 'cancelado');

  -- Lógica de Atualização
  IF active_orders_count > 0 THEN
    -- Se tem pedido aberto, força status OCUPADA
    UPDATE public.mesas 
    SET status = 'ocupada' 
    WHERE id = target_table_id 
    AND status != 'ocupada'; -- Só atualiza se necessário para evitar loop
  ELSE
    -- Se não tem pedido aberto, libera a mesa
    UPDATE public.mesas 
    SET status = 'livre' 
    WHERE id = target_table_id 
    AND status != 'livre';
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Criar o Gatilho (Trigger) que dispara a função
DROP TRIGGER IF EXISTS on_order_change_sync_table ON public.pedidos;

CREATE TRIGGER on_order_change_sync_table
AFTER INSERT OR UPDATE OR DELETE ON public.pedidos
FOR EACH ROW EXECUTE FUNCTION public.sync_table_status();