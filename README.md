# Raga — BMI Calculator

**Raga** is a Flutter-based BMI (Body Mass Index) calculator. Beyond the
number itself, it keeps your history, draws trend charts, figures out your
ideal weight, BMR, and daily calorie needs, handles multiple profiles, and
can share your result as an image.

A personal project — built to be genuinely useful, not just a demo.

## Features

**Required:**
- Height input (cm/in)
- Weight input (kg/lb)
- Automatic BMI calculation
- Visual gauge indicator + color per category
- Categories: Underweight, Normal, Overweight, Obese
- Health tips per category, in plain casual English

**Bonus:**
- **History + trend chart** — save every result, weight/BMI chart per month
- **Extra calculators** — ideal weight, BMR (Mifflin-St Jeor), daily calories + activity level
- **Multi-profile** — calculate BMI for family/friends in one app
- **Share result** — export the result card as an image
- **Light glassmorphism theme** + metric/imperial unit toggle
- **Cloud backup** (Supabase) — automatic backup, visible status in Profile, auto-retry, works 100% offline
- **Weekly reminder** — optional local notification every Sunday morning to weigh in
- **Weight goal** — set a target, see your progress and an estimated timeline from your trend
- **Export CSV** — share your full history as a CSV file

## Screenshots

Screenshots will be added after the first on-device build.
Meanwhile, install the APK from the [Release page](../../releases/tag/latest)
and try it yourself.

## Running it

Needs [Flutter](https://docs.flutter.dev/get-started/install) 3.47+.

```bash
flutter pub get
flutter run
```

Manual release APK build:

```bash
flutter build apk --release
```

> Note: every push to `main` triggers GitHub Actions, which builds the APK
> and attaches it to [Release "latest"](../../releases/tag/latest).
> Easiest way to get the APK: download it from there.

## Supabase setup (optional)

Without this the app runs fully offline on local storage.
Supabase is used for cloud backup of every saved entry.

1. Create a free project at [supabase.com](https://supabase.com).
2. In **Authentication → Sign In / Up**, enable **Allow anonymous sign-ins**.
3. In the **SQL Editor**, run this schema:

```sql
create table bmi_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  profile_id text not null,
  height_cm double precision not null,
  weight_kg double precision not null,
  bmi double precision not null,
  category text not null,
  created_at timestamptz default now()
);

alter table bmi_records enable row level security;

create policy "own rows"
  on bmi_records for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

4. Grab the **Project URL** and **anon key** from **Project Settings → API**.
5. For a local build:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxx
```

For GitHub Actions, add them as repository secrets
`SUPABASE_URL` and `SUPABASE_ANON_KEY` (Settings → Secrets → Actions).
The `supabase-keepalive.yml` workflow uses the same secrets to ping
every hour so the free-tier project doesn't get paused.

> Heads-up: mix up the two secrets and the app will tell you — the backup
> status in Profile shows exactly what went wrong.

## Project structure

```
lib/
  main.dart            # entry point, bottom nav shell
  core/
    bmi.dart           # BMI math, categories, ideal weight, BMR, calories
    tips.dart          # health tips per category
    theme.dart         # light theme: palette, HealthBg artwork, glass
  models/              # Profile, BmiRecord
  state/app_state.dart # global state (plain ChangeNotifier)
  data/
    local_store.dart   # local storage (the source of truth)
    cloud_sync.dart    # Supabase backup + visible status & auto-retry
  widgets/             # gauge, glass nav, glass cards, input cards, chips
  screens/             # Calculate, Result, History, Health, Profile
assets/
  images/raga-background.svg  # background artwork
```

## Privacy

Raga has no ads, no analytics, and doesn't sell data.
Full details: [PRIVACY.md](PRIVACY.md).

## License

MIT — see [LICENSE](LICENSE).
