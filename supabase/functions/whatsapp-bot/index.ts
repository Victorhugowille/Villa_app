import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

async function sendZapiReply(instanceId: string, token: string, userPhone: string, messageText: string) {
  const phone = userPhone.replace('@c.us', '');
  console.log(`Tentando enviar resposta para ${phone}...`);

  try {
    const response = await fetch(`https://api.z-api.io/instances/${instanceId}/token/${token}/send-text`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone, message: messageText }),
    });

    // MUDANÇA CRÍTICA: Vamos ler e mostrar a resposta da Z-API, NÃO IMPORTA O QUE SEJA.
    const responseBody = await response.text();
    console.log(`RESPOSTA DA Z-API: status=${response.status}, body=${responseBody}`);

    if (response.ok) {
      console.log('Status da resposta é OK (2xx).');
    } else {
      console.error('Status da resposta NÃO é OK.');
    }

  } catch (e) {
    console.error("ERRO CRÍTICO NA FUNÇÃO fetch:", e);
  }
}

serve(async (req: Request) => {
  if (req.method === 'POST') {
    try {
      const payload = await req.json();
      console.log('Payload completo recebido:', JSON.stringify(payload, null, 2));

      if (payload.isGroup === false && !payload.fromMe && payload.phone && payload.instanceId) {
        
        const instanceId = payload.instanceId;
        const userPhone = payload.phone;
        const receivedText = payload.text?.message?.trim() || '(Mensagem não textual)';

        const supabaseAdmin = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
          { auth: { persistSession: false } }
        );

        const { data: company, error } = await supabaseAdmin
          .from('companies')
          .select('*')
          .eq('zapi_instance_id', instanceId)
          .single();
        
        if (error || !company) {
           console.error('Empresa não encontrada para o instanceId:', instanceId);
           return new Response('OK', { status: 200 });
        }

        console.log(`Empresa encontrada: ${company.name}`);
        const responseText = `Olá, sou um robô da ${company.name}.`;
        await sendZapiReply(company.zapi_instance_id, company.zapi_token, userPhone, responseText);
        
      } else {
        console.log(`Evento ignorado. Motivo: isGroup=${payload.isGroup}, fromMe=${payload.fromMe}`);
      }
      
      return new Response('OK', { status: 200 });

    } catch (error) {
      console.error('Ocorreu um erro inesperado no processamento.', error);
      return new Response('Internal Server Error', { status: 500 });
    }
  }
  return new Response('Aguardando POST.', { status: 404 });
});