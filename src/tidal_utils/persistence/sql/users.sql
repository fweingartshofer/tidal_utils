-- name: get_user_by_id :one
select id, tidal_id, refresh_token, access_token, session_id from users where id = ?;

-- name: get_user_by_tidal_id :one
select id, tidal_id, refresh_token, access_token, session_id from users where tidal_id = ?;

-- name: get_user_by_session_id :one
select id, tidal_id, refresh_token, access_token, session_id from users where session_id = ?;

-- name: user_exists_by_tidal_id :one
SELECT EXISTS(SELECT 1 FROM users WHERE tidal_id = ? LIMIT 1);

-- name: insert_user :exec
INSERT into users(id, tidal_id, refresh_token, access_token, session_id) 
values (?, ?, ?, ?, ?)
RETURNING *;

-- name: update_user_by_id :exec
UPDATE users
set refresh_token = ?,
access_token = ?,
session_id = ?
WHERE id = ?;

-- name: update_user_by_tidal_id :exec
UPDATE users
set refresh_token = ?,
access_token = ?,
session_id = ?
WHERE tidal_id = ?;

-- name: initialize_users_table :exec
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    tidal_id TEXT not null unique,
    refresh_token TEXT unique,
    access_token TEXT unique,
    session_id TEXT unique
);
