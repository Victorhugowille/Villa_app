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
      Deno.env.get('PROJECT_URL')!,
      Deno.env.get('SERVICE_ROLE_KEY')!
    );

    // Pega o ID da solicitação do corpo da requisição
    const { request_id } = await req.json();
    if (!request_id) throw new Error("Request ID é obrigatório.");

    // Busca os dados da solicitação original
    const { data: request, error: requestError } = await supabaseAdmin
      .from('join_requests')
      .select('*')
      .eq('id', request_id)
      .single();

    if (requestError) throw requestError;
    if (request.status !== 'pending') throw new Error("Esta solicitação já foi processada.");

    // 1. Cria o novo usuário no sistema de autenticação do Supabase
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: request.requester_email,
      password: request.requester_password,
      email_confirm: true, // Já marca o e-mail como confirmado
    });

    if (authError) throw authError;

    // 2. Cria o perfil para o novo usuário na tabela 'profiles'
    const { error: profileError } = await supabaseAdmin.from('profiles').insert({
      user_id: authUser.user.id,
      company_id: request.target_company_id,
      role: 'employee', // Ou o cargo padrão que você quiser
      phone_number: request.requester_phone,
    });

    if (profileError) {
      // Se der erro ao criar o perfil, apaga o usuário recém-criado para não deixar lixo
      await supabaseAdmin.auth.admin.deleteUser(authUser.user.id);
      throw profileError;
    }

    // 3. Atualiza o status da solicitação para 'approved'
    await supabaseAdmin
      .from('join_requests')
      .update({ status: 'approved' })
      .eq('id', request.id);

    return new Response(JSON.stringify({ message: "Usuário aprovado e criado com sucesso!" }), { headers: corsHeaders });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
})