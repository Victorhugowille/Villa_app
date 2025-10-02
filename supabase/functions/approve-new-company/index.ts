import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function getAuthenticatedUser(req: Request, supabaseClient: SupabaseClient) {
  const token = req.headers.get('Authorization')?.replace('Bearer ', '');
  if (!token) throw new Error('Token de autenticação não encontrado.');
  const { data: { user }, error } = await supabaseClient.auth.getUser(token);
  if (error) throw new Error('Token inválido ou expirado.');
  if (!user) throw new Error('Usuário não autenticado.');
  return user;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
  const supabaseClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!);

  try {
    const adminUser = await getAuthenticatedUser(req, supabaseClient);
    if (adminUser.email !== 'victorhugowille@gmail.com') {
      return new Response(JSON.stringify({ error: "Acesso não autorizado." }), { status: 403, headers: corsHeaders });
    }

    const { request_id } = await req.json();
    if (!request_id) throw new Error("O ID da solicitação é obrigatório.");

    const { data: request, error: requestError } = await supabaseAdmin
      .from('signup_requests').select('*').eq('id', request_id).single();

    if (requestError) throw requestError;
    if (request.status !== 'pending') throw new Error("Esta solicitação já foi processada.");

    const { data: company, error: companyError } = await supabaseAdmin
      .from('companies').insert({
        name: request.company_name,
        cnpj: request.company_cnpj,
        notification_email: request.user_email,
      }).select().single();

    if (companyError) throw companyError;

    // Passo A: Cria o usuário na autenticação (sem metadados)
    const { data: auth, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: request.user_email,
      password: request.user_password,
      email_confirm: true,
    });

    if (authError) {
      await supabaseAdmin.from('companies').delete().eq('id', company.id);
      throw authError;
    }

    // Passo B: Cria o perfil manualmente na tabela 'profiles'
    const { error: profileError } = await supabaseAdmin.from('profiles').insert({
      user_id: auth.user.id,
      company_id: company.id,
      role: 'owner',
      phone_number: request.company_phone,
    });

    if (profileError) {
      // Se criar o perfil falhar, desfaz tudo
      await supabaseAdmin.auth.admin.deleteUser(auth.user.id);
      await supabaseAdmin.from('companies').delete().eq('id', company.id);
      throw profileError;
    }

    await supabaseAdmin.from('signup_requests').update({ status: 'approved' }).eq('id', request.id);

    return new Response(JSON.stringify({ message: "Empresa e usuário administrador criados com sucesso!" }), { headers: corsHeaders });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders });
  }
});