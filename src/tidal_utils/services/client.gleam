import flwr_oauth2/bearer_token
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import tidal_utils/services/json_api
import tidal_utils/services/tidal_types
import woof

//const user_playlists_endpoint = "https://openapi.tidal.com/v2/playlists"

const user_collections_endpoint = "https://openapi.tidal.com/v2/userCollectionPlaylists/me"

pub fn retrieve_playlists(access_token: String) {
  let assert Ok(req) =
    uri.parse(user_collections_endpoint) |> result.try(request.from_uri)
  let req = req |> request.set_query([#("include", "items")])

  let res =
    req
    |> bearer_token.attach_bearer_token_string_to_header(access_token)
    |> httpc.send
    |> woof.log_error("Error while sending http request", [
      #("url", user_collections_endpoint),
    ])
  use res: response.Response(String) <- result.try(
    res |> result.map_error(fn(_) { Nil }),
  )
  let body =
    res.body
    |> json.parse(json_api.json_api_response_decoder(
      tidal_types.playlist_decoder(),
      decode.dynamic,
    ))

  body |> log_result(res) |> result.map_error(fn(_) { Nil })
}

fn log_result(body, response: response.Response(String)) {
  case body {
    Ok(json_api.SuccessResponse(..)) -> {
      woof.info("Successfully requested user data", [])
    }
    Ok(json_api.ErrorResponse(_meta, _jsonapi, _links, errors)) ->
      woof.warning(
        "Got error response",
        list.index_map(errors, fn(error: json_api.Error, i: Int) -> #(
          String,
          String,
        ) {
          #(int.to_string(i), {
            option.unwrap(error.title, "Unknown title")
            <> ": "
            <> option.unwrap(error.detail, "")
          })
        }),
      )
    Error(error) -> {
      woof.error("Unable to decode response", [#("payload", response.body)])
      echo error
      Nil
    }
  }
  body
}
