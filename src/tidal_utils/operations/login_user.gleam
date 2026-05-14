import dream/http.{type Request}
import flwr_oauth2.{type AccessTokenResponse}
import flwr_oauth2/authorization_grant.{type AuthorizationResponse}
import flwr_oauth2/pkce
import gleam/dict
import gleam/httpc
import gleam/option
import gleam/result
import gleam/uri
import tidal_utils/services.{type Services}
import woof

pub type FetchTokenError {
  InvalidCallbackRequest
  AuthorziationRejected
  UnknownAuthorization
  NoRefreshTokenPresent
  InternalError
}

pub fn execute(
  req: Request,
  services: Services,
  session_id: String,
) -> Result(Nil, FetchTokenError) {
  use resp <- result.try(parse_callback(req))

  let verifier = get_verifier(resp, services)

  case resp {
    authorization_grant.ErrorResponse(..) -> handle_auth_error(resp, services)
    _ -> handle_success(resp, verifier, services, session_id)
  }
}

fn parse_callback(
  req: Request,
) -> Result(AuthorizationResponse, FetchTokenError) {
  req.query
  |> uri.parse_query()
  |> result.map(dict.from_list)
  |> result.map(authorization_grant.parse_authorization_response_query)
  |> result.replace_error(authorization_grant.ParseError(option.None))
  |> result.flatten()
  |> woof.log_error("Could not parse callback", [])
  |> result.replace_error(InvalidCallbackRequest)
}

fn get_verifier(
  resp: AuthorizationResponse,
  services: Services,
) -> option.Option(pkce.Verifier) {
  let verifier =
    resp.state
    |> option.map(services.get_verifier(services, _))
    |> option.flatten()
  resp.state |> option.map(services.remove_verifier(services, _))

  verifier
}

fn handle_auth_error(resp, services) {
  let assert authorization_grant.ErrorResponse(
    state: state,
    error: error,
    error_description: error_description,
    error_uri: error_uri,
  ) = resp

  state |> option.map(services.remove_verifier(services, _))

  woof.info("No authorization was given", [
    #("error", error),
    #("error_description", option.unwrap(error_description, "None")),
    #(
      "error_uri",
      error_uri
        |> option.map(uri.to_string)
        |> option.unwrap("None"),
    ),
  ])

  Error(AuthorziationRejected)
}

fn handle_success(resp, verifier, services, session_id) {
  case verifier {
    option.None -> {
      woof.info("Got redirect without state", [])
      Error(UnknownAuthorization)
    }

    option.Some(verifier) -> {
      exchange_token(resp, verifier, services, session_id)
    }
  }
}

fn exchange_token(resp, verifier, services, session_id) {
  use token_req <- result.try(build_token_request(resp, verifier, services))
  use http_req <- result.try(to_http_request(token_req))
  use response <- result.try(send_request(http_req))
  use parsed <- result.try(parse_token_response(response))
  store_tokens(parsed, services, session_id)
}

fn build_token_request(resp, verifier, services: Services) {
  authorization_grant.to_token_request_with_pkce_verifier(
    resp,
    services.config.token_uri,
    flwr_oauth2.ClientSecretPost(
      services.config.client_id,
      services.config.secret,
    ),
    option.Some(services.config.redirect_uri),
    verifier,
  )
  |> result.replace_error(InvalidCallbackRequest)
}

fn to_http_request(req) {
  req
  |> flwr_oauth2.to_http_request()
  |> result.replace_error(InvalidCallbackRequest)
}

fn send_request(req) {
  httpc.send(req)
  |> woof.log_error("Could not retrieve tokens from OAuth 2.0 server", [])
  |> result.replace_error(InvalidCallbackRequest)
}

fn parse_token_response(response) {
  flwr_oauth2.parse_token_response(response)
  |> woof.log_error("Could not retrieve tokens from OAuth 2.0 server", [])
  |> result.replace_error(InvalidCallbackRequest)
}

fn store_tokens(
  response: AccessTokenResponse,
  services: Services,
  session_id: String,
) {
  services
  |> services.upsert_user(session_id, response)
  |> result.replace_error(InternalError)
  |> result.replace(Nil)
}
