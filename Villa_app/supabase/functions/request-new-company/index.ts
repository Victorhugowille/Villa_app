import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const { companyName, cnpj, phone, email, password } = await req.json();

    if (!companyName || !cnpj || !phone || !email || !password) {
      throw new Error("Todos os campos são obrigatórios.");
    }

    const { error } = await supabaseAdmin.from('signup_requests').insert({
      company_name: companyName,
      company_cnpj: cnpj,
      company_phone: phone,
      user_email: email,
      user_password: password, // Veja a nota de segurança abaixo
      status: 'pending',
    });

    if (error) throw error;

    return new Response(JSON.stringify({ message: "Solicitação enviada com sucesso!" }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
})