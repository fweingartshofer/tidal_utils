import dream/http.{type Request, type Response}
import gleam/option
import gleam/string
import tidal_utils/components/layout
import tidal_utils/services.{type Services}
import tidal_utils/tidal_auth_context.{type TidalAuthContext}

pub fn after_handler(
  request: Request,
  context: TidalAuthContext,
  services: Services,
  next: fn(Request, TidalAuthContext, Services) -> Response,
) -> Response {
  let resp = next(request, context, services)
  let res =
    resp.content_type
    |> option.map(string.contains(_, "text/html"))
    |> option.unwrap(False)
  case res {
    True -> layout.wrap(resp)
    False -> resp
  }
}
