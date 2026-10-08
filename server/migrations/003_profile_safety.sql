CREATE TABLE IF NOT EXISTS profile_shortlists (
  owner_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_user_id, profile_user_id),
  CHECK (owner_user_id <> profile_user_id)
);

CREATE INDEX IF NOT EXISTS profile_shortlists_recent_idx
  ON profile_shortlists (owner_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS profile_blocks (
  blocker_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (blocker_user_id, blocked_user_id),
  CHECK (blocker_user_id <> blocked_user_id)
);

CREATE INDEX IF NOT EXISTS profile_blocks_blocked_idx
  ON profile_blocks (blocked_user_id, blocker_user_id);
