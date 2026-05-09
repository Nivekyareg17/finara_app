-- Run this once in your PostgreSQL database before/after deploying the backend.
-- It is safe to run more than once.

ALTER TABLE users
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

CREATE TABLE IF NOT EXISTS blocked_users (
    id SERIAL PRIMARY KEY,
    blocker_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT blocked_users_no_self_block CHECK (blocker_id <> blocked_id),
    CONSTRAINT blocked_users_unique_pair UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS ix_blocked_users_blocker_id
ON blocked_users(blocker_id);

CREATE INDEX IF NOT EXISTS ix_blocked_users_blocked_id
ON blocked_users(blocked_id);
