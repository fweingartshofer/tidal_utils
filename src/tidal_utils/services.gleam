import dream_ets/config
import dream_ets/operations
import dream_ets/table.{type Table}
import flwr_oauth2.{type AccessTokenResponse}
import flwr_oauth2/authorization_grant.{type State, Code, S256, State} as auth_grant
import flwr_oauth2/pkce.{type Verifier, Verifier}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/option
import gleam/result
import gleam/uri
import tidal_utils/config as tidal_config
import tidal_utils/model.{type Tokens}
import woof

pub type Services {
  Services(
    oauth_cache: Table(State, Verifier),
    tidal_cache: Table(String, Tokens),
    config: tidal_config.Config,
  )
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
  use tidal_cache <- result.try(
    config.new("tidal_cache")
    |> config.key(dynamic.string, decode.string)
    |> config.value(model.tokens_encoder, model.tokens_decoder())
    |> config.create()
    |> result.replace_error(Nil),
  )
  Ok(Services(oauth_cache, tidal_cache, config))
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
      |> option.Some
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

pub fn get_verifier(services: Services, state: State) -> option.Option(Verifier) {
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

pub fn insert_tokens(
  services: Services,
  session_id: String,
  tokens: AccessTokenResponse,
) {
  services.tidal_cache
  |> operations.insert_new(
    session_id,
    tokens |> model.from_access_token_response(),
  )
}

pub fn get_tokens(services: Services, session_id: String) {
  let tokens = services.tidal_cache |> operations.get(session_id)
  case tokens {
    Ok(tokens) -> tokens
    Error(_err) -> {
      woof.warning("Got an error when trying to access table for tidal_auths", [
        #("session_id", session_id),
      ])
      option.None
    }
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
