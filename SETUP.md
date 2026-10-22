# JDS Keyhold — Supabase + Resend setup checklist

Do not paste secret keys into chat, commit them to source control, or place server secrets in browser/mobile code. You can share project URLs and non-secret configuration status; keep API keys private.

## 1. Create Supabase

1. Go to https://supabase.com/ and create/sign in to your account.
2. Create a new project named `jds-keyhold-dev` (choose a strong database password and store it securely).
3. Choose a region appropriate for your users and confirm latency/data-residency considerations before production.
4. In Project Settings → API, copy the **Project URL** and the **publishable/anon key** for client configuration. Keep the **service_role/secret key** private on the server only.
5. Open SQL Editor and review `supabase/schema.sql` before running it on a fresh development project. Do not run on a production database without a reviewed migration plan.
6. In Authentication → URL Configuration, configure local development and your intended production site URLs. Enable the sign-in methods you intend to support and set secure redirect URLs.
7. Configure email confirmation and password reset flows. Do not rely on client-side UI for authorization.
8. In Storage, create private buckets for lease agreements, receipts, meter-reading photos, and tenant documents. Add object-level RLS policies before uploading real files.
9. Add database functions for atomic payment posting/allocation, audit events, membership invitations, invoice status changes, and safe tenant account linking.
10. Test two separate landlord workspaces and two tenants. Confirm each tenant cannot read another tenant's invoice, payment, or document, including through direct REST requests.

## 2. Create Resend

1. Go to https://resend.com/ and create/sign in to your account.
2. Add a sending domain you control and complete the DNS verification steps.
3. Create an API key with the minimum required permissions.
4. Store the key as a server-side secret (for Supabase Edge Functions, use the Supabase project secrets configuration). Never put it in the frontend or Flutter app.
5. Verify a test email from a server-side function before enabling tenant invitations, receipts, or reminders.
6. Configure email templates for account verification, password reset (if applicable), tenant invitations, rent reminders, receipt delivery, and maintenance notifications.
7. Add delivery-failure handling, retry limits, rate limits, and logs that do not expose sensitive tenant details.

## 3. Environment variables

Copy `.env.example` into a local environment file only when you start the production web app. Keep `.env.local` out of version control.

- `NEXT_PUBLIC_SUPABASE_URL`: Supabase project URL.
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: publishable/anon key; safe for client use only with correct RLS.
- `SUPABASE_SERVICE_ROLE_KEY`: server only, never expose to client bundles.
- `RESEND_API_KEY`: server only.
- `EMAIL_FROM`: address on the verified sending domain.

## 4. Before real users or real payments

- Review and complete RLS policies and storage object policies.
- Implement server-side validation and atomic payment allocations; never trust client-calculated balances.
- Add idempotency keys and reconciliation for mobile-money webhooks.
- Define receipt numbering and immutable snapshots of invoice line items/tariffs.
- Confirm EFRIS obligations and integration path with URA/qualified tax advice; an app-generated PDF must not be misrepresented as an official EFRIS receipt.
- Review Uganda data protection obligations and create privacy, retention, access, and incident-response processes.
- Enable backups and complete a restore test.
- Add automated tests, rate limits, error monitoring, and a production security review.
