-- Run this in Supabase SQL Editor if messages read receipts (ticks) don't work.
-- Adds the is_read column required for single grey / double orange tick.

ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;

-- Optional: backfill existing rows so old messages don't show as "unread"
-- UPDATE messages SET is_read = true WHERE is_read IS NULL;
