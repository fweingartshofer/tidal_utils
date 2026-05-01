import dream/http.{type Request, type Response}
import dream/http/status
import gleam/option
import tidal_utils/components/error
import tidal_utils/components/json_api_error
import tidal_utils/components/login_button
import tidal_utils/components/playlists
import tidal_utils/operations/create_redirect_uri
import tidal_utils/services
import tidal_utils/services/client
import tidal_utils/services/json_api
import tidal_utils/tidal_auth_context.{type TidalAuthContext}

pub fn render(
  _request: Request,
  context: TidalAuthContext,
  services: services.Services,
) -> Response {
  case context.access_token {
    option.Some(access_token) -> {
      let playlists = client.retrieve_playlists(access_token)
      case playlists {
        Ok(json_api.ErrorResponse(..) as resp) ->
          json_api_error.render(status.internal_server_error, resp.errors)
        Ok(json_api.SuccessResponse(..) as resp) ->
          playlists.render(resp.included |> option.unwrap([]))
        Error(_) ->
          error.render(
            status.internal_server_error,
            "Couldn't retrieve playlist data",
          )
      }
    }

    _ -> {
      let res = services |> create_redirect_uri.execute()
      case res {
        option.Some(red_uri) -> {
          red_uri |> login_button.render()
        }
        _ ->
          error.render(
            status.internal_server_error,
            "An unexpected error occured",
          )
      }
    }
  }
}
