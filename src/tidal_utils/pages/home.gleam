import dream/http.{type Request, type Response}
import dream/http/response
import dream/http/status
import gleam/option
import lustre/element
import tidal_utils/components/error
import tidal_utils/components/greeting
import tidal_utils/components/layout
import tidal_utils/components/login_button
import tidal_utils/components/playlists
import tidal_utils/operations/create_redirect_uri
import tidal_utils/services.{type Services}
import tidal_utils/services/client
import tidal_utils/tidal_auth_context.{type TidalAuthContext}

pub fn render(
  _request: Request,
  context: TidalAuthContext,
  services: Services,
) -> Response {
  case context.access_token {
    option.Some(access_token) -> render_authenticated(access_token)
    _ -> render_unauthenticated(services)
  }
  |> layout.wrap_()
  |> response.html_response(status.ok, _)
}

fn render_authenticated(access_token) {
  let playlists = client.retrieve_playlists(access_token)
  let self = client.retrieve_self(access_token)
  case playlists {
    Error(_) -> error.render("Couldn't retrieve user data")
    Ok(playlists) -> render_success(playlists, self)
  }
}

fn render_success(playlists, self) {
  element.fragment([
    greeting.render(self |> option.from_result()),
    playlists.render(playlists),
  ])
}

fn render_unauthenticated(services) {
  case services |> create_redirect_uri.execute() {
    option.Some(red_uri) -> login_button.render(red_uri)
    _ -> error.render("An unexpected error occured")
  }
}
