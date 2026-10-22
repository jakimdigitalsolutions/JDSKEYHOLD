# JDS Keyhold — deployment and backend setup

## What is included in this package
- `index.html`, `styles.css`, `app.js`: responsive landlord dashboard / tenant portal *prototype*. Its portfolio data and actions are still local demo data; they do not yet read/write Supabase.
- `auth.html`: real Supabase email/password sign-up, sign-in, and password reset UI once you configure the public Supabase project URL/key and apply the SQL scripts. Landlord sign-up creates a workspace via the trigger. Tenant invitation/lease linking is not implemented yet.
- `assets/keyhold-icon.png`: JDS Keyhold app-icon concept based on the new premium brand direction.
- `supabase/schema.sql`: initial relational schema and initial RLS policies.
- `supabase/002-auth-onboarding.sql`: creates profiles and landlord workspaces after Supabase Auth sign-up.
- `supabase/functions/send-test-email/index.ts`: authenticated Resend delivery-test Edge Function.
- `supabase/RESEND-SETUP.md`: custom-domain and email instructions.

## Recommended setup order
1. Register a domain you own if you want branded email. `jdskeyhold.pages.dev` can host the website, but you cannot verify the shared `pages.dev` domain in Resend because you cannot control its DNS.
2. In a fresh Supabase development project, run `supabase/schema.sql`, then `supabase/002-auth-onboarding.sql` in separate SQL Editor queries.
3. In Supabase Auth URL Configuration, allow `https://jdskeyhold.pages.dev/auth.html` and your later custom-domain auth URL.
4. Put the Supabase Project URL and public publishable/anon key into `supabase-config.js`. This is public client config; never use a service-role key there.
5. Deploy `supabase/functions/send-test-email` and store `RESEND_API_KEY` and `EMAIL_FROM` as Supabase secrets after your sending domain is verified. Follow `supabase/RESEND-SETUP.md`.
6. Test account creation, sign-in, password reset and the test email with a test account.

## Production security warning
This package is not production-approved and does not yet connect the landlord dashboard to the database. Do not upload real tenant identity documents or rely on the demo tenant switch for access control. Before launch, implement and test tenant invitations, server-side account-to-lease linking, secure private Storage policies, atomic payment/invoice updates, payment allocation limits, audit events, MFA, rate limiting, monitoring, and backups. Have a qualified reviewer test that one tenant/landlord cannot access another user's records.

## Cloudflare Pages
The current app is static HTML/CSS/JS: framework preset `None`, build command blank, output directory `.` when the files are at the repository root. If the files are nested inside a project subfolder, set Root directory or output directory to the folder containing `index.html`. Add the `supabase-config.js` file with public values only; do not commit any secret keys.
