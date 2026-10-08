CREATE INDEX IF NOT EXISTS users_active_discovery_order_idx
  ON users (created_at DESC, id)
  WHERE account_status = 'active' AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS profiles_visible_city_idx
  ON profiles (lower(city))
  WHERE visibility = 'visible';

CREATE INDEX IF NOT EXISTS profiles_visible_state_idx
  ON profiles (lower(state))
  WHERE visibility = 'visible';

CREATE INDEX IF NOT EXISTS profiles_visible_education_idx
  ON profiles (lower(education))
  WHERE visibility = 'visible' AND education IS NOT NULL;
