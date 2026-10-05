# Anbu Matrimony Phase 1 Starter

This repository was initially a quotation-only workspace. The application blueprint and initial mobile/API scaffolding are now under `mobile/` and `server/`.

## Deliverables

- Architecture, ERD, access rules, platform policies, and launch guidance: [docs/IMPLEMENTATION_BLUEPRINT.md](docs/IMPLEMENTATION_BLUEPRINT.md)
- Flutter starter: `mobile/`
- Express/PostgreSQL API starter and migration: `server/`

## API setup

1. Install Node.js 20 or later and PostgreSQL.
2. Create a database and copy `server/.env.example` to `server/.env`.
3. Generate random secrets using an approved secret manager. `DATA_ENCRYPTION_KEY` must be base64 for exactly 32 random bytes. Do not use the example placeholders.
4. Install and type-check:

   ```powershell
   Set-Location server
   npm install
   npm run typecheck
   npm run build
   ```

5. Apply `server/migrations/001_initial_schema.sql` to a new PostgreSQL database using your migration/release process, for example `psql "$env:DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations\001_initial_schema.sql`.
6. Configure production TLS, backups/restore tests, monitoring, secret rotation, OTP provider integration, token issuance, store verification, and admin authorization before launch.

`GET /health` checks database connectivity. `GET /api/v1/profiles/:userId` requires a signed HS256 access token with issuer, audience, issued-at, expiration, and a 15-minute maximum age, plus an active phone-verified account. `POST /api/v1/interests` atomically enforces the five-per-India-local-day free interest limit. The JWT guard is not an OTP login implementation: MSG91/Fast2SMS challenge generation and verification, abuse protection, and session issuance still need a provider integration.

## Flutter setup

Install Flutter and the Android/iOS toolchains. This workspace contains the app source and native integration samples, but not the generated Gradle/Xcode host projects. Generate those from a matching Flutter SDK into a clean temporary Flutter project, merge the `lib/`, `assets/`, localization, and dependencies from `mobile/`, then apply the supplied Kotlin/Swift channel implementations. Do not overwrite the supplied Dart app source when generating platform hosts. Then run:

```powershell
Set-Location mobile
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
```

This starter contains a minimal app shell, English/Tamil localization, a profile entitlement helper, and the Android secure-window channel. iOS screenshot prevention is not supported; the iOS channel is deliberately a no-op. Store billing clients and server validation must be integrated and tested before production.
