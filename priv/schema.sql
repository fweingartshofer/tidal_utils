CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    tidal_id TEXT not null unique,
    refresh_token TEXT unique,
    access_token TEXT unique,
    session_id TEXT unique
);
