import dream/http.{type Request, type Response}
import gleam/option
import tidal_utils/model.{type TidalConnection}
import tidal_utils/operations/refresh_token.{
  type RefreshError, CouldNotRefreshTokensError, NoRefreshTokenGivenError,
  TokensNotFound,
}
import tidal_utils/services.{type Services}
import tidal_utils/tidal_auth_context.{type TidalAuthContext, TidalAuthContext}
import woof

pub fn handle(
  request: Request,
  context: TidalAuthContext,
  services: Services,
  next: fn(Request, TidalAuthContext, Services) -> Response,
) -> Response {
  let user =
    refresh_token.execute(services, context.session_id)
    |> log(context)
  let new_ctx =
    TidalAuthContext(
      ..context,
      access_token: user
        |> option.from_result()
        |> option.map(fn(x) { x.access_token })
        |> option.flatten(),
    )
  next(request, new_ctx, services)
}

fn log(
  tokens: Result(TidalConnection, RefreshError),
  context: TidalAuthContext,
) -> Result(TidalConnection, RefreshError) {
  let ctx = [#("session_id", context.session_id)]
  case tokens {
    Ok(_) -> woof.debug("Successfully retrieved tokens", ctx)
    Error(NoRefreshTokenGivenError) ->
      woof.info(
        "Could not retrieve new access token, since no refresh token was given",
        ctx,
      )
    Error(CouldNotRefreshTokensError) ->
      woof.error("Could not retrieve a new access token", ctx)
    Error(TokensNotFound) ->
      woof.info(
        "Could not find any tokens associated with given session_id",
        ctx,
      )
  }
  tokens
}
