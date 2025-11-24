import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Função de resposta REESCRITA para a ChatPro API
async function sendChatProReply(hostUrl: string, instanceKey: string, token: string, userPhone: string, messageText: string) {
  // O ChatPro espera o número no formato DDI+DDD+Numero (sem o @c.us)
  const phone = userPhone.replace('@c.us', '');
  console.log(`Tentando enviar resposta (ChatPro) para ${phone}...`);

  // Monta a URL (ex: https://host.com/instancia/send-message)
  const chatProEndpoint = `${hostUrl}/${instanceKey}/send-message`;

  try {
    const response = await fetch(chatProEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token // O ChatPro usa o Token no Header 'Authorization'
      },
      body: JSON.stringify({
        "number": phone,
        "message": messageText
      }),
    });

    const responseBody = await response.json();
    console.log(`RESPOSTA DA CHATPRO API: status=${response.status}`, responseBody);

    if (response.ok) {
      console.log('Mensagem enviada com sucesso.');
    } else {
      console.error('Falha ao enviar mensagem.');
    }

  } catch (e) {
    console.error("ERRO CRÍTICO NA FUNÇÃO fetch (ChatPro):", e);
  }
}

serve(async (req: Request) => {
  if (req.method === 'POST') {
    try {
      const payload = await req.json();
      console.log('Payload completo recebido (ChatPro):', JSON.stringify(payload, null, 2));

      // 1. O webhook do ChatPro tem uma estrutura diferente
      // O evento de nova mensagem é 'messages.upsert'
      if (payload.event === 'messages.upsert' && payload.codigo && payload.payload) {
        
        const instanceKey = payload.codigo; // ex: 'chatpro-fv89duxqn4'
        const data = payload.payload;

        // 2. O local dos dados mudou
        const userPhone = data.from;
        const fromMe = data.isFromMe;
        const isGroup = data.isGroupMsg;
        const receivedText = data.body?.trim() || '(Mensagem não textual)';

        // 3. Lógica de filtro
        if (instanceKey && userPhone && !isGroup && !fromMe) {
          
          const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
            { auth: { persistSession: false } }
          );

          // 4. Consulta usando as NOVAS colunas (api_...)
          const { data: company, error } = await supabaseAdmin
            .from('companies')
            .select('name, api_host_url, api_instance_key, api_token')
            .eq('api_instance_key', instanceKey) // Busca pela 'api_instance_key'
            .single();
          
          if (error || !company) {
            console.error('Empresa não encontrada para o instanceKey:', instanceKey, error);
            return new Response('OK', { status: 200 }); 
          }

          if (!company.api_host_url || !company.api_token) {
             console.error(`Empresa ${company.name} não tem 'api_host_url' ou 'api_token' configurados no DB.`);
             return new Response('OK', { status: 200 });
          }

          console.log(`Empresa encontrada: ${company.name}`);
          const responseText = `Olá, sou um robô da ${company.name}.`;

          // 5. Chama a NOVA função de envio do ChatPro
          await sendChatProReply(
            company.api_host_url,
            company.api_instance_key,
            company.api_token,
            userPhone,
            responseText
          );
          
        } else {
          console.log(`Evento ignorado. Motivo: isGroup=${isGroup}, fromMe=${fromMe}`);
        }
      }
      
      return new Response('OK', { status: 200 });

    } catch (error) {
      console.error('Ocorreu um erro inesperado no processamento.', error);
      return new Response('Internal Server Error', { status: 500 });
    }
  }
  return new Response('Aguardando POST.', { status: 404 });
});