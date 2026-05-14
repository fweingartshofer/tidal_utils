import dream_ets/config
import dream_ets/operations
import dream_ets/table.{type Table}
import flwr_oauth2.{type AccessTokenResponse}
import flwr_oauth2/authorization_grant.{type State, Code, S256, State} as auth_grant
import flwr_oauth2/pkce.{type Verifier, Verifier}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/option.{Some}
import gleam/result
import gleam/uri
import tidal_utils/config as tidal_config
import tidal_utils/model.{TidalConnection}
import tidal_utils/persistence/db
import woof
import youid/uuid

pub type Services {
  Services(oauth_cache: Table(State, Verifier), config: tidal_config.Config)
}

pub fn new() -> Result(Services, Nil) {
  use config <- result.try(tidal_config.create())
  use oauth_cache <- result.try(
    config.new("authorization_cache")
    |> config.key(encode_state, decode_state())
    |> config.value(encode_verifier, decode_verifier())
    |> config.create()
    |> result.replace_error(Nil),
  )
  let assert Ok(_) = config |> db.initialize_db()
  Ok(Services(oauth_cache, config))
}

pub fn create_redirect_uri(services: Services) {
  let state = auth_grant.random_state32()
  let verifier = pkce.new()
  let challenge = verifier |> pkce.to_challenge()
  let conf = services.config
  let res = services |> insert_state_and_verifier(state, verifier)
  case res {
    Ok(True) ->
      auth_grant.new()
      |> auth_grant.set_authorization_endpoint(conf.authorization_uri)
      |> auth_grant.set_response_type(Code)
      |> auth_grant.set_redirect_uri(conf.redirect_uri)
      |> auth_grant.set_client_id(conf.client_id)
      |> auth_grant.set_scope(conf.scope)
      |> auth_grant.set_state(state)
      |> auth_grant.set_code_challenge(challenge.value, S256)
      |> auth_grant.make_redirect_uri()
      |> uri.to_string()
      |> Some
    _ -> option.None
  }
}

pub fn insert_state_and_verifier(
  services: Services,
  state: State,
  verifier: Verifier,
) -> Result(Bool, table.EtsError) {
  services.oauth_cache
  |> operations.insert_new(state, verifier)
}

pub fn get_verifier(
  services: Services,
  state: State,
) -> option.Option(Verifier) {
  let verifier = services.oauth_cache |> operations.get(state)
  case verifier {
    Ok(verifier) -> verifier
    Error(_err) -> {
      woof.warning("Got an error when trying to access table for verifiers", [
        #("state", state.value),
      ])
      option.None
    }
  }
}

pub fn remove_verifier(services: Services, state: State) {
  let res = services.oauth_cache |> operations.delete(state)
  case res {
    Error(_err) ->
      woof.warning(
        "Got an error while trying to remove state from table for verifiers",
        [#("state", state.value)],
      )
    _ -> Nil
  }
}

pub fn upsert_user(
  services: Services,
  session_id: String,
  tokens: AccessTokenResponse,
) {
  woof.info("Received access token and refresh token", [
    #("session_id", session_id),
    #("Access Token", tokens.access_token),
    #("Refresh Token", tokens.refresh_token |> option.unwrap("")),
  ])
  let payload = tokens.access_token |> model.decode_token()
  use payload <- result.try(payload)
  woof.debug("Inserting user with tokens", [#("session_id", session_id)])
  let tidal_connection =
    TidalConnection(
      id: uuid.v7(),
      tidal_id: payload.uid,
      refresh_token: tokens.refresh_token,
      access_token: Some(tokens.access_token),
      session_id: Some(session_id),
    )
  let inserted =
    services.config
    |> db.upsert_user_by_tidal_id(tidal_connection, _)
  case inserted {
    False -> Error(Nil)
    True -> Ok(tidal_connection)
  }
}

fn encode_state(state: State) -> dynamic.Dynamic {
  dynamic.string(state.value)
}

fn decode_state() -> decode.Decoder(State) {
  decode.string |> decode.map(State)
}

fn encode_verifier(verifier: Verifier) -> dynamic.Dynamic {
  dynamic.string(verifier.value)
}

fn decode_verifier() -> decode.Decoder(Verifier) {
  decode.string |> decode.map(Verifier)
}
