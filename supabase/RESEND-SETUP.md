# Resend email setup — JDS Keyhold

## First: the current `pages.dev` address is not an email-sending domain
`https://jdskeyhold.pages.dev/` is a Cloudflare-hosted site address. You do not control the parent `pages.dev` DNS zone, so you cannot add the DNS records Resend requires to verify `pages.dev` as your sender domain. The site can stay on Pages while you buy a domain you control, such as `jdskeyhold.com` if available, or a suitable alternative. Do not assume a name is available until you check with a registrar.

You do not need to move the website to make email work. After you own the domain, keep the website on Cloudflare Pages and add the exact DNS records Resend gives you at the DNS provider. You can use a dedicated sending subdomain such as `mail.yourdomain.com` and a sender such as `JDS Keyhold <notifications@mail.yourdomain.com>`.

## Step 1 — register and connect your domain
1. Register a domain through a registrar you trust.
2. In Cloudflare Pages → your project → Custom domains, add the domain or a subdomain such as `app.yourdomain.com` and follow the DNS instructions.
3. In Resend → Domains → Add Domain, enter the sending domain you want to verify (often a dedicated subdomain).
4. Copy the exact SPF/DKIM and any other records Resend shows into the authoritative DNS provider. Do not guess record values and do not delete existing mail records.
5. Wait for Resend to show the domain as verified.

## Step 2 — add server-side secrets
Create an API key in Resend with only the permissions needed to send email. From a terminal with Supabase CLI installed and linked to your project, run these commands after replacing the placeholders locally:

```sh
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set RESEND_API_KEY=re_your_actual_key EMAIL_FROM='JDS Keyhold <notifications@mail.yourdomain.com>'
supabase functions deploy send-test-email
```

Never commit real keys to GitHub or place the Resend key in `supabase-config.js`, HTML, browser JavaScript, or Flutter. Keep the key only in Supabase Edge Function secrets.

## Step 3 — send a test email
1. In Supabase Authentication, create a test user and confirm the email address.
2. Sign in through `auth.html` after configuring `supabase-config.js`.
3. Call the deployed `send-test-email` Edge Function from an authenticated test client. The function sends only to the signed-in user's own confirmed email.
4. Check Resend's email logs and the inbox/spam folder.

Example curl (replace placeholders locally; never share the access token):

```sh
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-test-email' \
  -H 'Authorization: Bearer USER_ACCESS_TOKEN' \
  -H 'apikey: YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  --data '{}'
```

This is a delivery test only. Tenant invitations, billing notices, rent reminders, receipts, retries, templates, preferences, and rate limits require separate implementation and testing. Do not use this function as a general arbitrary-recipient sender.
