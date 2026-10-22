import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const resendKey = Deno.env.get('RESEND_API_KEY');
  const emailFrom = Deno.env.get('EMAIL_FROM');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!resendKey || !emailFrom || !supabaseUrl || !supabaseAnonKey) {
    return new Response(JSON.stringify({ error: 'Server email configuration is incomplete.' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) return new Response(JSON.stringify({ error: 'Sign in is required.' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const supabase = createClient(supabaseUrl, supabaseAnonKey, { global: { headers: { Authorization: authHeader } }, auth: { persistSession: false, autoRefreshToken: false } });
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user?.email || !user.email_confirmed_at) return new Response(JSON.stringify({ error: 'A signed-in user with a confirmed email is required.' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: emailFrom,
      to: [user.email],
      subject: 'JDS Keyhold — email connection test',
      text: `Hello ${user.user_metadata?.full_name || 'there'},\n\nThis is a test email from JDS Keyhold. Your Resend connection is working.\n\nThis is only a delivery test; rent reminders and tenant receipts are not enabled by this test function.\n\nJakim Digital Solutions`,
    }),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) return new Response(JSON.stringify({ error: 'Resend could not send the test message.', details: result }), { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  return new Response(JSON.stringify({ ok: true, message: 'Test email accepted by Resend.', id: result.id }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
});
