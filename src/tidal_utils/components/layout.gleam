import dream/http
import dream/http/response.{Response, Text}
import tidal_utils/components/navbar

pub fn wrap(original_response: http.Response) {
  case original_response.body {
    Text(body) -> {
      let body =
        { "
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Tidal Utils</title>
</head>
<body>
    " <> navbar.render() <> "
    <main>
    " <> body <> "
    </main>
</body>
</html>" }
        |> Text
      Response(..original_response, body:)
    }
    _ -> original_response
  }
}
