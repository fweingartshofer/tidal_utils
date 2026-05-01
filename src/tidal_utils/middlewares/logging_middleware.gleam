import dream/http.{type Request, type Response}
import gleam/option
import tidal_utils/services.{type Services}
import tidal_utils/tidal_auth_context.{type TidalAuthContext}
import woof

pub fn handle(
  request: Request,
  context: TidalAuthContext,
  services: Services,
  next: fn(Request, TidalAuthContext, Services) -> Response,
) -> Response {
  woof.debug("Got request", [
    #("method", request.method |> http.method_to_string()),
    #("endpoint", request.path),
    #("query", request.query),
    #("session_id", context.session_id),
    #("access_token", context.access_token |> option.unwrap("")),
  ])
  next(request, context, services)
}
