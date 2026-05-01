import dream/http.{type Request, type Response}
import dream/http/cookie
import dream/http/response.{Response}
import gleam/option
import tidal_utils/services.{type Services}
import tidal_utils/tidal_auth_context.{type TidalAuthContext, TidalAuthContext}
import youid/uuid

pub fn handle(
  request: Request,
  context: TidalAuthContext,
  services: Services,
  next: fn(Request, TidalAuthContext, Services) -> Response,
) -> Response {
  let session_id =
    request.cookies
    |> http.get_cookie_value("session_id")
    |> option.lazy_unwrap(uuid.v7_string)
  let new_context = TidalAuthContext(..context, session_id:)
  let session_cookie = cookie.simple_cookie("session_id", session_id)

  let response = next(request, new_context, services)
  let cookies = response.cookies |> cookie.set_cookie(session_cookie)
  Response(..response, cookies:)
}
