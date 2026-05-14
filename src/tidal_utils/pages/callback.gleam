import dream/http.{type Request, type Response}
import dream/http/response
import dream/http/status
import tidal_utils/components/error
import tidal_utils/components/layout
import tidal_utils/operations/login_user
import tidal_utils/services
import tidal_utils/tidal_auth_context.{type TidalAuthContext}
import woof

pub fn render(
  req: Request,
  context: TidalAuthContext,
  services: services.Services,
) -> Response {
  woof.info("Request query", [#("Query", req.query)])
  case login_user.execute(req, services, context.session_id) {
    Ok(_) -> response.redirect_response(status.temporary_redirect, "/")
    Error(_) ->
      error.render("Could not log you in")
      |> layout.wrap_()
      |> http.html_response(status.internal_server_error, _)
  }
}
