import flwr_oauth2.{RefreshTokenGrantRequest}
import gleam/httpc
import gleam/option
import gleam/order
import gleam/result
import gleam/time/timestamp
import tidal_utils/model.{type Tokens}
import tidal_utils/services.{type Services}
import woof

pub type RefreshError {
  NoRefreshTokenGivenError
  CouldNotRefreshTokensError
  TokensNotFound
}

pub fn execute(
  services: Services,
  session_id: String,
) -> Result(Tokens, RefreshError) {
  let tokens =
    services
    |> services.get_tokens(session_id)
    |> option.to_result(TokensNotFound)
  use tokens <- result.try(tokens)
  let is_valid =
    tokens.expires_at
    |> option.map(timestamp.compare(timestamp.system_time(), _))
    |> option.map(fn(x) { x == order.Lt })
    |> option.unwrap(True)
  case is_valid {
    True -> Ok(tokens)
    False -> exchange_tokens(services, session_id, tokens)
  }
}

fn exchange_tokens(services: Services, session_id: String, tokens: Tokens) {
  let refresh_token =
    tokens.refresh_token |> option.to_result(NoRefreshTokenGivenError)
  use refresh_token <- result.try(refresh_token)
  let config = services.config
  let request =
    flwr_oauth2.to_http_request(RefreshTokenGrantRequest(
      token_endpoint: config.token_uri,
      authentication: flwr_oauth2.ClientSecretPost(
        config.client_id,
        config.secret,
      ),
      refresh_token: refresh_token,
      scope: config.scope,
    ))
    |> result.replace_error(CouldNotRefreshTokensError)
  use request <- result.try(request)
  use response <- result.try(
    httpc.send(request) |> result.replace_error(CouldNotRefreshTokensError),
  )
  use token_response <- result.try(
    flwr_oauth2.parse_token_response(response)
    |> result.replace_error(CouldNotRefreshTokensError),
  )
  let _ =
    token_response
    |> services.insert_tokens(services, session_id, _)
    |> woof.log_error("Could not insert tokens into table", [])
  token_response
  |> model.from_access_token_response()
  |> Ok
}
