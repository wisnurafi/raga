# Security Policy — Raga

Raga is a solo side project (a campus assignment), maintained best-effort.
If you find a security problem, I'd genuinely like to hear about it — here's
how to reach me safely.

## Reporting a vulnerability

- **Preferred:** open a private GitHub Security Advisory on this repo
  (Security tab → "Report a vulnerability").
- Do NOT open a public issue with exploit details.

Tell me what you found, how to reproduce it, and what you think the impact
is. I'll acknowledge your report and ship a fix as soon as I can — give me
a few days, this is a one-person project.

## What's in scope

- The app code in `lib/` (Flutter).
- The Supabase schema and Row Level Security policies in `supabase/`.
- The CI workflows in `.github/workflows/`.

Out of scope: Supabase and GitHub themselves (report to them directly), and
vulnerable third-party packages (report upstream — I'll bump the dependency
once a fix is out).

## One thing that is NOT a vulnerability

The Supabase anon key baked into the APK is public by design — it's a
client-side key and can't do anything beyond what Row Level Security allows.
The real boundary is the RLS policies, so that's where to look if you're
auditing.

## Supported versions

Only the latest build from the `main` branch (the `latest` release). Older
APKs don't get patches — just grab the newest one.
