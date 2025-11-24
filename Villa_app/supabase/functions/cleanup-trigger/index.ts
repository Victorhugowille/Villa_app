import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (_req: Request) => {
  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    // Chama a função SQL que acabamos de criar
    const { data, error } = await supabaseAdmin.rpc('delete_auth_trigger');

    if (error) throw error;

    return new Response(JSON.stringify({ message: data }), { headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
})