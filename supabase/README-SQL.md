# Supabase SQL setup — JDS Keyhold

## Before you run SQL
Use a fresh **development** Supabase project. Do not run this over an existing production database. Save a backup first if you have data. The scripts are a development foundation and still need a professional security review before real tenant/financial data is stored.

## Run in this order
1. Open Supabase Dashboard → SQL Editor → New query.
2. Open `schema.sql` in a plain-text editor and copy the SQL. The first line must start with two hyphens: `--` (PostgreSQL comment), not a single hyphen.
3. Paste and run `schema.sql`.
4. Open another SQL Editor query, paste `002-auth-onboarding.sql`, and run it.
5. In Authentication → URL Configuration, add your Cloudflare site URL `https://jdskeyhold.pages.dev` to the allowed Site URL / Redirect URLs as appropriate. Add your custom domain later when you attach it.
6. In Table Editor, verify the tables and policies exist. Test with two separate accounts before using real tenant data.

The trigger creates a profile for new auth users and a workspace plus owner membership for landlord sign-ups. It does not implement tenant invitations or link a tenant to a lease. Do not treat the tenant demo toggle in `index.html` as real access control.

## Browser configuration
Copy your project URL and public publishable/anon key into the placeholders in `../supabase-config.js`. Those values are intended for public clients; RLS is what protects data. Never use the `service_role` key in the browser, GitHub, Flutter app, or public files.

## Launch blockers
Before production, add and test tenant invitation/claim RPCs, atomic payment allocations, invoice balance constraints, secure private Storage bucket policies, audit-event write functions, rate limiting, MFA policy, backups, and negative tests proving users cannot read/write other organizations' records. A successful SQL run alone does not prove the application is secure.
