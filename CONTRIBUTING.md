# Contributing — Raga

Thanks for wanting to contribute!

## Getting started

1. You need Flutter 3.47+ — see the [official install guide](https://docs.flutter.dev/get-started/install).
2. Clone this repo, then:

```bash
flutter pub get
flutter run
```

3. Make sure `flutter analyze` passes with zero issues before pushing.

## Ground rules

- **One change, one commit.** Clear commit messages, e.g.
  `feat(history): add per-profile filter`.
- Never commit secrets: API keys, `.env`, or keystores.
  Supabase credentials only go through `--dart-define` / GitHub Secrets.
- App copy is in plain casual English — a non-technical person should
  understand every word on screen. Keep jargon out of user-facing text.
- Follow the existing design language (purple, rounded cards). If you want
  to change the look significantly, open an *issue* first.

## Reporting bugs

Open a new *issue* with:

- **Repro steps:** ...
- **What happened:** ...
- **What should happen:** ...
- **Device:** (e.g. Redmi Note 12, Android 13)
