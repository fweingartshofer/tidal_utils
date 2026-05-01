import dream/http
import dream/http/response
import dream/http/status

pub fn render(redirect_uri: String) -> http.Response {
  { "
  <h1>Welcome to Tidal Utils</h1>
  <a href=" <> redirect_uri <> ">Tidal Login</a>
  " }
  |> response.html_response(status.ok, _)
}
