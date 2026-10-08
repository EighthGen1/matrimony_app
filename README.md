# Anbu Matrimony Phase 1 Starter

This repository was initially a quotation-only workspace. The application blueprint and initial mobile/API scaffolding are now under `mobile/` and `server/`.

## Deliverables

- Architecture, ERD, access rules, platform policies, and launch guidance: [docs/IMPLEMENTATION_BLUEPRINT.md](docs/IMPLEMENTATION_BLUEPRINT.md)
- Flutter starter: `mobile/`
- Express/PostgreSQL API starter and migration: `server/`

## API setup

1. Install Node.js 20 or later and PostgreSQL.
2. Create the `anbu_matrimony` database in pgAdmin or with `createdb anbu_matrimony`, then copy `server/.env.example` to `server/.env`. If PowerShell cannot find `psql` or `createdb`, install PostgreSQL command-line tools and add the PostgreSQL `bin` directory (for example, `C:\Program Files\PostgreSQL\16\bin`) to `PATH`, then open a new PowerShell window and verify with `Get-Command psql, createdb`.
3. Generate random secrets using an approved secret manager. `DATA_ENCRYPTION_KEY` must be base64 for exactly 32 random bytes. Do not use the example placeholders.
4. Install and type-check:

   ```powershell
   Set-Location server
   npm install
   npm run typecheck
   npm run build
   ```

5. Apply `server/migrations/001_initial_schema.sql` to a new PostgreSQL database using your migration/release process, for example `psql "$env:DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations\001_initial_schema.sql`.
6. Apply subsequent additive migrations in order, including `migrations/002_discovery_indexes.sql` and `migrations/003_profile_safety.sql`.
7. For local development only, create fictional profiles with `npm run seed:dev`. This command refuses to run unless `NODE_ENV=development`.
8. Start the API locally with `npm run dev` and confirm `GET http://localhost:3000/health` returns `{"status":"ok","database":"ok"}`.
9. Configure production TLS, backups/restore tests, monitoring, secret rotation, OTP provider integration, token issuance, store verification, and admin authorization before launch.

`GET /health` checks database connectivity. `GET /api/v1/profiles/:userId` requires a signed HS256 access token with issuer, audience, issued-at, expiration, and a 15-minute maximum age, plus an active phone-verified account. `POST /api/v1/interests` atomically enforces the five-per-India-local-day free interest limit. The JWT guard is not an OTP login implementation: MSG91/Fast2SMS challenge generation and verification, abuse protection, and session issuance still need a provider integration.

## Run the Flutter profile against the API

Install Flutter, start PostgreSQL and the API as described above, and make sure `server/.env` allows `http://localhost:5173` in `CORS_ORIGINS`. The app loads a profile from `GET /api/v1/profiles/:userId`; it requires a valid access token for an active, phone-verified account.

The Discover tab calls authenticated `GET /api/v1/profiles` with server-side pagination and optional gender, age, city, state, education, and verification filters. It returns only public profile-card fields. Apply migrations 002 and 003 before using discovery and profile-safety operations. The app also supports shortlist add/remove, interest submission, reports, and block/unblock; reports are stored for moderation and blocked accounts are excluded from discovery and profile access.

The API starter does not yet implement OTP login or access-token issuance. For local testing only, the following creates a 15-minute token for the synthetic profile. Do not use this method for real accounts or production:

```powershell
Set-Location server
$env:PROFILE_ID = "4be0d7e5-1490-45f4-9920-583f5dc03d76"
$token = node -e "require('dotenv').config(); const jwt=require('jsonwebtoken'); process.stdout.write(jwt.sign({}, process.env.AUTH_JWT_SECRET, { algorithm: 'HS256', subject: process.env.PROFILE_ID, issuer: process.env.AUTH_JWT_ISSUER, audience: process.env.AUTH_JWT_AUDIENCE, expiresIn: '15m' }))"
```

In the same PowerShell window, start the Flutter web app:

```powershell
Set-Location ..\mobile
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=PROFILE_ID=4be0d7e5-1490-45f4-9920-583f5dc03d76 "--dart-define=DEV_ACCESS_TOKEN=$token"
```

For an Android emulator, use `http://10.0.2.2:3000` as `API_BASE_URL`; a physical phone needs the computer's reachable LAN address and matching CORS configuration. `DEV_ACCESS_TOKEN` is only read in debug mode and must never be supplied to release builds. A production login flow must obtain tokens from the server and store/manage them using an appropriate secure session flow. The Android host project is configured; iOS host setup, production authentication, store verification, and OTP integrations still need implementation.

The app currently includes Discover, Shortlist, and My Profile tabs. Discovery supports authenticated server-side pagination and filters; profile detail exposes shortlist, express-interest, report, and block operations through authenticated APIs. Reports are queued for moderation; push notifications and recipient accept/decline flows are not implemented yet. No compatibility percentage is shown because partner-preference storage and a tested matching model do not exist yet.

### Android development build

The Android host project is generated under `mobile/android`; open `mobile/` in Android Studio. The application ID is `com.anbumatrimony.app`. For a local debug build, run `flutter build apk --debug`. The debug APK builds successfully; emulator installation and on-device interaction testing remain intentionally deferred. To use the emulator with the local development API later, start the API, create a short-lived development token as above, then run from `mobile/`:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=PROFILE_ID=4be0d7e5-1490-45f4-9920-583f5dc03d76 "--dart-define=DEV_ACCESS_TOKEN=$token"
```

The cleartext HTTP exception is present only in the Android debug manifest for the local emulator. Production must use HTTPS. iOS host configuration and release signing are not configured; do not distribute a release build until signing, OTP authentication/token issuance, account creation/deletion, privacy/legal review, billing verification, moderation operations, and end-to-end security checks are complete.
