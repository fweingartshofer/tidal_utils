import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import parrot/dev
import sqlight
import tidal_utils/config.{type Config}
import tidal_utils/model
import tidal_utils/sql
import woof
import youid/uuid

pub fn initialize_db(config: Config) {
  use conn <- sqlight.with_connection(config.database_url)
  let #(s, _) = sql.initialize_users_table()
  s |> sqlight.exec(conn) |> log_error()
}

pub fn upsert_user_by_tidal_id(
  user: model.TidalConnection,
  config: Config,
) -> Bool {
  case user_exists_by_tidal_id(user, config) {
    True -> update_user_by_tidal_id(user, config)
    False -> insert_user(user, config)
  }
}

pub fn user_exists_by_tidal_id(
  user: model.TidalConnection,
  config: Config,
) -> Bool {
  let #(s, with, decoder) = sql.user_exists_by_tidal_id(user.tidal_id)
  let with = list.map(with, parrot_to_sqlight)
  use conn <- sqlight.with_connection(config.database_url)
  let exists =
    s
    |> sqlight.query(conn, with, decoder)
    |> log_error()
    |> option.from_result()
  {
    use exists <- option.map(exists)
    case exists {
      [res, ..] -> res.col_0 > 0
      [] -> False
    }
  }
  |> option.unwrap(False)
}

pub fn insert_user(user: model.TidalConnection, config: Config) {
  woof.debug("Inserting new user", [#("id", user.id |> uuid.to_string())])
  let #(s, with) =
    sql.insert_user(
      id: user.id |> uuid.to_string(),
      tidal_id: user.tidal_id,
      refresh_token: user.refresh_token,
      access_token: user.access_token,
      session_id: user.session_id,
    )
  let with = list.map(with, parrot_to_sqlight)
  use conn <- sqlight.with_connection(config.database_url)
  s
  |> sqlight.query(conn, with, sql.insert_user_decoder())
  |> log_error()
  |> result.is_ok()
}

pub fn update_user_by_tidal_id(user: model.TidalConnection, config: Config) {
  woof.debug("Updating existing user", [#("id", user.id |> uuid.to_string())])
  let #(s, with) =
    sql.update_user_by_tidal_id(
      tidal_id: user.tidal_id,
      refresh_token: user.refresh_token,
      access_token: user.access_token,
      session_id: user.session_id,
    )
  let with = list.map(with, parrot_to_sqlight)
  use conn <- sqlight.with_connection(config.database_url)
  s
  |> sqlight.query(conn, with, decode.success(""))
  |> log_error()
  |> result.is_ok()
}

pub fn get_user_by_session_id(session_id: String, config: Config) {
  let #(s, with, decoder) =
    sql.get_user_by_session_id(session_id: option.Some(session_id))
  let with = list.map(with, parrot_to_sqlight)
  use conn <- sqlight.with_connection(config.database_url)
  let res =
    s
    |> sqlight.query(conn, with, decoder)
    |> log_error()
    |> result.replace_error(Nil)
  use users <- result.try(res)
  case users {
    [
      sql.GetUserBySessionId(
        id:,
        tidal_id:,
        refresh_token:,
        access_token:,
        session_id:,
      ),
      ..
    ] -> {
      let assert Ok(id) = uuid.from_string(id)
      Ok(model.TidalConnection(
        id:,
        tidal_id:,
        refresh_token:,
        access_token:,
        session_id:,
      ))
    }
    [] -> {
      woof.info("No user found", [#("session_id", session_id)])
      Error(Nil)
    }
  }
}

fn parrot_to_sqlight(param: dev.Param) -> sqlight.Value {
  case param {
    dev.ParamFloat(x) -> sqlight.float(x)
    dev.ParamInt(x) -> sqlight.int(x)
    dev.ParamString(x) -> sqlight.text(x)
    dev.ParamBitArray(x) -> sqlight.blob(x)
    dev.ParamNullable(x) -> sqlight.nullable(fn(a) { parrot_to_sqlight(a) }, x)
    dev.ParamList(_) -> panic as "sqlite does not implement lists"
    dev.ParamBool(_) -> panic as "sqlite does not support booleans"
    dev.ParamDate(_) -> panic as "sqlite does not support dates"
    dev.ParamTimestamp(_) -> panic as "sqlite does not support timestamps"
    dev.ParamDynamic(_) ->
      panic as "Dynamic not supported by this implementation"
  }
}

fn log_error(error: Result(a, sqlight.Error)) {
  case error {
    Ok(_) -> {
      woof.debug("Successfully executed query", [])
    }
    Error(error) ->
      woof.error("Encountered error when executing sql query", [
        #("code", error.code |> sqlight.error_code_to_int() |> int.to_string()),
        #("message", error.message),
      ])
  }
  error
}
