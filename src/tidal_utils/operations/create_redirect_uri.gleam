import flwr_oauth2/authorization_grant.{Code, S256} as auth_grant
import flwr_oauth2/pkce
import gleam/option
import gleam/uri
import tidal_utils/services.{type Services}

pub fn execute(services: Services) {
  let state = auth_grant.random_state32()
  let verifier = pkce.new()
  let challenge = verifier |> pkce.to_challenge()
  let conf = services.config
  let res = services |> services.insert_state_and_verifier(state, verifier)
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
