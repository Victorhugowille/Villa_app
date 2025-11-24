import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
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

    // Agora esperamos também o 'role' vindo do app
    const { request_id, role } = await req.json(); 
    if (!request_id) throw new Error("Request ID é obrigatório.");
    if (!role || (role !== 'employee' && role !== 'owner')) {
      throw new Error("O cargo (role) é inválido ou não foi fornecido. Deve ser 'employee' ou 'owner'.");
    }

    const { data: request, error: requestError } = await supabaseAdmin
      .from('join_requests').select('*').eq('id', request_id).maybeSingle();

    if (requestError) throw requestError;
    if (!request) throw new Error(`Solicitação com ID ${request_id} não encontrada.`);
    if (request.status !== 'pending') throw new Error("Esta solicitação já foi processada.");

    let userId: string;
    const { data: { users }, error: listError } = await supabaseAdmin.auth.admin.listUsers({
      email: request.requester_email,
      page: 1,
      perPage: 1,
    });

    if (listError) throw listError;
    const existingUser = users.length > 0 ? users[0] : null;
    
    if (existingUser) {
      userId = existingUser.id;
    } else {
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: request.requester_email,
        password: request.requester_password,
        email_confirm: true,
      });
      if (createError) throw createError;
      userId = newUser.user.id;
    }

    const { error: profileError } = await supabaseAdmin.from('profiles').insert({
      user_id: userId,
      company_id: request.target_company_id,
      role: role, // <-- USAMOS O CARGO RECEBIDO AQUI
      phone_number: request.requester_phone,
    });

    if (profileError) {
      if (!existingUser) {
        await supabaseAdmin.auth.admin.deleteUser(userId);
      }
      throw profileError;
    }

    await supabaseAdmin.from('join_requests').update({ status: 'approved' }).eq('id', request.id);

    return new Response(JSON.stringify({ message: "Usuário aprovado com sucesso!" }), { headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: corsHeaders });
  }
})