import dream/http.{type Request, type Response}
import dream/http/status
import tidal_utils/operations/fetch_tokens
import tidal_utils/services
import tidal_utils/tidal_auth_context.{type TidalAuthContext}
import woof

pub fn render(
  req: Request,
  context: TidalAuthContext,
  services: services.Services,
) -> Response {
  woof.info("Request query", [#("Query", req.query)])
  case fetch_tokens.execute(req, services, context.session_id) {
    Ok(_) -> http.html_response(status.ok, "You were successfully logged in")
    Error(_) ->
      http.html_response(status.internal_server_error, "Could not log you in")
  }
}
