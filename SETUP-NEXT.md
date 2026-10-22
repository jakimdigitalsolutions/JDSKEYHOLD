# JDS Keyhold — next setup steps

1. **Supabase SQL:** follow `supabase/README-SQL.md` and run `supabase/schema.sql` only in a fresh development project.
2. **Supabase Auth:** set your site URL and allowed redirect URLs in Authentication → URL Configuration. Use test accounts first.
3. **Resend:** follow `supabase/RESEND-SETUP.md`, verify a domain, add server-side secrets, and deploy the test email function.
4. **Keep credentials private:** the project URL and publishable/anon key can be used by the client only with correct RLS. Never expose service-role/secret keys or database passwords.
5. **Important:** the current web prototype still uses sample/local browser data and is not yet connected to Supabase. The Flutter app is a UI shell. Do not treat test email success as proof that login, tenant isolation, billing, receipts, or meter billing are live.
