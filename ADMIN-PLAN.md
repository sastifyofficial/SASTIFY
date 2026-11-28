# SASTIFY Admin Panel — Final Master Plan

## Decisions
- Design: professional, clean and responsive.
- Access: only the Owner. No other admins or moderators.
- Security: Supabase Auth plus a database-backed Owner allowlist protected by RLS.
- JIBOFY is separate and will not be changed.

## Build order
1. Owner authentication, database allowlist, RLS and logout.
2. Dashboard with real metrics only.
3. Welcome Page Editor: logo, favicon, loader, images, text, community post, founder/team, section order and visibility, theme, colors, fonts, animations, SEO, preview and publish.
4. User management and account moderation.
5. Blue Tick and Verified Tick applications, pricing, duration, payments and renewals.
6. Social posts, photos, videos, comments and reports moderation.
7. Shop sellers, seller plans/fees, products, categories, orders and returns.
8. Payments and finance: manual bKash, Nagad, Rocket, fees and refunds.
9. Notifications and announcements.
10. Reports and moderation history.
11. Website settings, policies, contact details, currency and maintenance mode.
12. Security review, backup, mobile testing, quota review and launch.

## Owner-only security requirements
- No public signup or browser UI can grant Owner access.
- Owner is registered manually in Supabase.
- Authenticated users can read only their own admin access row.
- Privileged writes must use RLS policies or server-side Edge Functions.
- Never put a service-role key in browser code.
- Record important Owner actions in an audit log.
- Admin page is excluded from search indexing.

## Current implementation status
- admin.html: planned professional Owner login and dashboard shell.
- supabase/admin_setup.sql: Owner access table and RLS bootstrap.
- Metrics remain blank until real database modules are connected.
- Management modules are not active until implemented.

## Setup needed
1. Ensure the Owner email exists in Supabase Auth: mdjihadofficial00@gmail.com.
2. Run supabase/admin_setup.sql in Supabase SQL Editor.
3. Verify one Owner row is returned.
4. Sign in at /admin.html.
