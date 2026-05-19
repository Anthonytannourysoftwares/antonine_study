-- Add image columns to lost_found_items
ALTER TABLE lost_found_items ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE lost_found_items ADD COLUMN IF NOT EXISTS image_data BYTEA;
ALTER TABLE lost_found_items ADD COLUMN IF NOT EXISTS image_mime VARCHAR(50);
