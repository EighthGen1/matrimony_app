CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE gender AS ENUM ('female', 'male', 'other');
CREATE TYPE created_for AS ENUM ('self', 'son', 'daughter', 'sibling', 'relative');
CREATE TYPE account_status AS ENUM ('pending', 'active', 'suspended', 'deleted');
CREATE TYPE moderation_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE media_kind AS ENUM ('profile_photo', 'horoscope_document', 'identity_document');
CREATE TYPE subscription_status AS ENUM ('pending', 'active', 'expired', 'revoked', 'refunded');
CREATE TYPE store_platform AS ENUM ('google_play', 'app_store');
CREATE TYPE interest_status AS ENUM ('pending', 'accepted', 'rejected', 'withdrawn');
CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read', 'removed');

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_e164_encrypted text NOT NULL,
  phone_lookup_hash text NOT NULL UNIQUE,
  gender gender NOT NULL,
  date_of_birth date NOT NULL,
  created_for created_for NOT NULL,
  account_status account_status NOT NULL DEFAULT 'pending',
  phone_verified_at timestamptz,
  verified_badge boolean NOT NULL DEFAULT false,
  identity_verified_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE profiles (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_first_name text NOT NULL CHECK (length(trim(display_first_name)) BETWEEN 1 AND 80),
  display_last_initial char(1) NOT NULL,
  full_name_encrypted text NOT NULL,
  marital_status text NOT NULL,
  religion text,
  caste text,
  sub_caste text,
  gothram text,
  education text,
  occupation text,
  designation text,
  income_range text,
  family_type text,
  family_status text,
  city text NOT NULL,
  state text NOT NULL,
  country_code char(2) NOT NULL DEFAULT 'IN',
  contact_email_encrypted text,
  bio text,
  visibility text NOT NULL DEFAULT 'visible' CHECK (visibility IN ('visible', 'hidden')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX profiles_discovery_idx
  ON profiles (city, state, marital_status, education)
  WHERE visibility = 'visible';

CREATE TABLE media_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind media_kind NOT NULL,
  object_key text NOT NULL UNIQUE,
  content_type text NOT NULL CHECK (content_type IN ('image/jpeg', 'image/webp', 'application/pdf')),
  byte_size bigint NOT NULL CHECK (byte_size > 0 AND byte_size <= 1048576),
  moderation_status moderation_status NOT NULL DEFAULT 'pending',
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT moderation_review_consistency CHECK (
    (moderation_status = 'pending' AND reviewed_at IS NULL)
    OR (moderation_status <> 'pending' AND reviewed_at IS NOT NULL)
  )
);
CREATE INDEX media_assets_pending_idx ON media_assets(created_at) WHERE moderation_status = 'pending';

CREATE TABLE profile_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  media_asset_id uuid NOT NULL UNIQUE REFERENCES media_assets(id) ON DELETE CASCADE,
  sort_order smallint NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, sort_order)
);

CREATE TABLE horoscopes (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  rasi text,
  natchathiram text,
  lagnam text,
  sevvai_dosham text CHECK (sevvai_dosham IN ('yes', 'no', 'unknown')),
  document_asset_id uuid REFERENCES media_assets(id) ON DELETE SET NULL,
  field_moderation_status moderation_status NOT NULL DEFAULT 'pending',
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_type text NOT NULL CHECK (plan_type = 'pass_90_day'),
  store store_platform NOT NULL,
  product_id text NOT NULL,
  store_transaction_id text NOT NULL UNIQUE,
  original_transaction_id text,
  purchase_token_hash text,
  currency char(3) NOT NULL,
  price_minor_units bigint NOT NULL CHECK (price_minor_units >= 0),
  starts_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  status subscription_status NOT NULL DEFAULT 'pending',
  verified_at timestamptz,
  last_store_event_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (expires_at > starts_at)
);
CREATE INDEX subscriptions_active_user_idx
  ON subscriptions(user_id, expires_at DESC)
  WHERE status = 'active' AND verified_at IS NOT NULL;

CREATE TABLE interests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status interest_status NOT NULL DEFAULT 'pending',
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (sender_id <> receiver_id),
  UNIQUE (sender_id, receiver_id)
);
CREATE INDEX interests_inbox_idx ON interests(receiver_id, created_at DESC);
CREATE INDEX interests_daily_limit_idx ON interests(sender_id, created_at);

CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz
);

CREATE TABLE conversation_members (
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  blocked_at timestamptz,
  PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  payload text NOT NULL CHECK (length(trim(payload)) BETWEEN 1 AND 4000),
  status message_status NOT NULL DEFAULT 'sent',
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz,
  CHECK (status <> 'read' OR read_at IS NOT NULL)
);
CREATE INDEX messages_conversation_idx ON messages(conversation_id, created_at DESC);

CREATE TABLE profile_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason text NOT NULL CHECK (reason IN ('fake_details', 'inappropriate_content', 'already_married', 'other')),
  details text,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  CHECK (reporter_id <> reported_user_id)
);

CREATE TABLE moderation_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id uuid REFERENCES media_assets(id) ON DELETE SET NULL,
  target_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reviewer_user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  decision moderation_status NOT NULL CHECK (decision <> 'pending'),
  reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX moderation_reviews_target_idx ON moderation_reviews(target_user_id, created_at DESC);
