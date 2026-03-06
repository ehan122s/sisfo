-- ============================================================
-- E-PKL Database Setup — Step 7: Seed Data
-- ============================================================
-- Default configuration values for a fresh deployment.
-- Run LAST after all other setup scripts.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- APP_CONFIG: WhatsApp Gateway defaults
-- ────────────────────────────────────────────────────────────
INSERT INTO app_config (key, value, description)
VALUES
    ('WA_GATEWAY_URL', 'https://api.fonnte.com/send', 'URL endpoint for WhatsApp Gateway'),
    ('WA_API_KEY', 'DUMMY_TOKEN_CHANGE_ME', 'API Key/Token for WhatsApp Gateway')
ON CONFLICT (key) DO NOTHING;
