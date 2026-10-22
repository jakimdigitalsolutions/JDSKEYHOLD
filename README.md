# JDS Keyhold — product prototype

A responsive, premium-style interactive preview for the JDS Keyhold rental/property management product by Jakim Digital Solutions.

## Run the preview

1. Unzip the project.
2. Open `index.html` in a modern browser, or serve the folder with any static web server (recommended):
   - Python: `python -m http.server 8080`
   - Then visit `http://localhost:8080`
3. Use **Landlord view / Tenant portal** to switch between the management workspace and a tenant's read-only example portal.
4. Try **Add property**, **Record payment**, **Enter reading**, exports, and the navigation.

The preview stores demo changes in this browser's `localStorage`. It does not connect to a database, send email, authenticate real users, or issue legally valid receipts. The sample figures and tariff values are illustrative.

## What is included

- `index.html`, `styles.css`, `app.js`: responsive interactive prototype.
- `supabase/schema.sql`: initial relational schema and starting RLS policies for Supabase/Postgres. It is a reviewable starting point, **not yet production-approved**.
- `mobile/`: initial Flutter application shell and implementation notes.
- `.env.example`: placeholders only; no secrets included.
- `SETUP.md`: steps to create/configure Supabase and Resend.

## Important product and security boundary

The prototype is for workflow validation only. Hiding tenant UI in the browser is not security. Production tenant privacy must be enforced by Supabase RLS and private object-storage policies on every request. Payment allocation, invoice status, role invitations, document access, audit events, EFRIS handling, and mobile-money verification need server-side logic and tests before real customer data is entered.

## Initial technology direction

- Web: Next.js + TypeScript (production app; this prototype is static HTML/CSS/JS so you can review it immediately).
- Mobile: Flutter.
- Backend: Supabase Auth + PostgreSQL + private Storage + Edge Functions.
- Transactional email: Resend via a server-side Edge Function or backend only.
- Money: integer UGX minor/whole currency units; all financial calculations server-side.

## Suggested next milestones

1. Review UI and flows with you.
2. Create Supabase project and configure Auth, schema, RLS, and private buckets.
3. Replace prototype sample data with real API queries; add sign-in, account setup, organization creation, and role invitations.
4. Implement unit/lease/tenant workflows and invoice/payment ledger with atomic RPCs and automated tests.
5. Implement utility tariff snapshots, submeter and shared-master-meter allocation, receipts/statements, and audit history.
6. Connect Resend, then printer support and the Flutter client.
7. Security review, backup/restore drill, EFRIS and payment provider validation, and pilot testing.
