# SASTIFY Admin Panel — Implementation Roadmap

## Product decisions
- Professional, responsive Owner control center.
- One privileged account: the Owner. No other admins or moderators.
- SASTIFY only. JIBOFY must remain untouched.
- Owner login uses Supabase Auth and the `public.admin_access` allowlist.
- Owner email configured so far: `muhammadjihadofficiaal@gmail.com`.
- Never place a Supabase service-role key in browser code.

## Delivery principles
- Build in dependency order; do not activate a module before its database schema, RLS rules, and real UI actions exist.
- Show only verified live data. Never invent dashboard counts, payment totals, or moderation states.
- Use additive, rerunnable SQL migrations. Preserve the existing `public.profiles` table and existing user data.
- Privileged mutations must be enforced by database policies or server-side Edge Functions, not by hiding buttons in the browser.
- Keep an audit trail for Owner actions.
- Test desktop and mobile layouts, authentication expiry, permission denial, and empty states.

## Implementation phases

### Phase 0 — Owner foundation
- Owner-only authentication and allowlist check.
- Logout and session validation.
- Responsive dashboard shell, module search, light/dark appearance.
- Admin page excluded from search indexing.
- Verify Owner row in Supabase before proceeding.

### Phase 1 — Database and profile foundation
- Inspect the existing profile schema before altering it.
- Add a unique public username and short human-readable Member ID without replacing Supabase UUIDs.
- Sync signup metadata to the profile record.
- Define safe profile, avatar and cover-photo storage policies.
- Add account status and Owner audit events with server-enforced permissions.

### Phase 2 — Welcome Page CMS
- Edit logo, favicon, loader, hero/community/founder images and all text.
- Manage section order, visibility, colors, typography, theme and animations.
- Preview draft and publish changes.
- Store settings in database and media in Storage; no hard-coded pretend save buttons.

### Phase 3 — Member management
- Live member list, search, filters and profile inspection.
- Suspend, restore and ban through secure server-side actions.
- Member ID, join date, account status and audit history.

### Phase 4 — Verification
- Blue Tick and Verified Tick product definitions, pricing and duration.
- Applications, payment review, approval, expiry and renewal.
- Keep paid verification distinct from identity checks and clearly label each.

### Phase 5 — Social moderation
- Posts, photos, videos, comments, reports and spam queues.
- Remove/restore content and record reason plus Owner action history.

### Phase 6 — Shop operations
- Seller onboarding and seller plans/fees.
- Product/category moderation, stock, orders, cancellations and returns.

### Phase 7 — Payments and finance
- Manual bKash, Nagad and Rocket records.
- Order payments, seller fees, refunds and withdrawal workflows.
- Reconciliation and downloadable reports; never expose private payment details to other users.

### Phase 8 — Reports, notifications and settings
- Platform reports, moderation history and audit log.
- Announcements and notifications.
- Policies, contact details, SEO, currency, language and maintenance mode.

### Phase 9 — Security and launch
- Review every RLS policy and Storage policy.
- Confirm no service-role key or privileged secret is in frontend code.
- Test Owner-only access, ordinary-user denial, mobile/desktop, backups and storage quotas.
- Enable features only after real end-to-end tests.

## Current verified implementation
- `admin.html`: Owner login checks Supabase Auth and the Owner allowlist; dashboard shell, responsive layout, module search and theme toggle are present in the repository.
- `supabase/admin_setup.sql`: creates `admin_access`, enables RLS, and seeds the configured Owner when that Auth user exists.
- Owner reports that the allowlist query returns their email with `owner` access.
- `signup.html`: multi-step account details, birthday, gender and optional profile photo flow exists. Username is currently only in Auth metadata; unique database enforcement is still pending.
- `profile.html`: basic profile display exists; it is not yet the complete social profile.
- `supabase/profile_storage.sql`: avatar bucket and owner-folder upload policies are prepared; execution in Supabase still needs confirmation.
- Dashboard metrics and management modules are not yet connected to real business tables/actions.

## Manual setup boundary
Repository changes can be committed, but SQL migrations must be run in the user's Supabase SQL Editor. Never claim a migration or Cloudflare deployment succeeded until the user or a status check confirms it.
