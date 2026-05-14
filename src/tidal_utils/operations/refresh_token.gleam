import flwr_oauth2.{RefreshTokenGrantRequest}
import gleam/httpc
import gleam/option
import gleam/result
import tidal_utils/model
import tidal_utils/persistence/db
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
) -> Result(model.TidalConnection, RefreshError) {
  let user =
    db.get_user_by_session_id(session_id, services.config)
    |> result.replace_error(TokensNotFound)
  use tokens <- result.try(user)
  let is_valid =
    tokens.access_token
    |> option.to_result(Nil)
    |> result.map(model.decode_token)
    |> result.flatten
    |> result.is_ok
  case is_valid {
    True -> Ok(tokens)
    False -> exchange_tokens(services, session_id, tokens)
  }
}

fn exchange_tokens(
  services: Services,
  session_id: String,
  user: model.TidalConnection,
) -> Result(model.TidalConnection, RefreshError) {
  let refresh_token =
    user.refresh_token |> option.to_result(NoRefreshTokenGivenError)
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
  token_response
  |> services.upsert_user(services, session_id, _)
  |> woof.log_error("Could not insert tokens into table", [])
  |> result.replace_error(CouldNotRefreshTokensError)
}
