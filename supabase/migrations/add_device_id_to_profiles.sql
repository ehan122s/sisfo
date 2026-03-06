-- Add device_id column to profiles table to store the bound device identifier
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS device_id TEXT;

-- Create an index for faster lookups (optional but good practice)
CREATE INDEX IF NOT EXISTS content_device_id_idx ON profiles(device_id);
