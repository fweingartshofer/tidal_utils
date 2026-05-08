import flwr_oauth2/bearer_token
import gleam/dynamic/decode
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/uri
import tidal_utils/services/json_api
import tidal_utils/services/tidal_types.{type Playlist}
import woof

//const user_playlists_endpoint = "https://openapi.tidal.com/v2/playlists"

const user_collections_endpoint = "https://openapi.tidal.com/v2/userCollectionPlaylists/me"

const user_self_endpoint = "https://openapi.tidal.com/v2/users/me"

pub fn retrieve_playlists(access_token: String) -> Result(List(Playlist), Nil) {
  let assert Ok(req) =
    uri.parse(user_collections_endpoint) |> result.try(request.from_uri)
  let res =
    req
    |> request.set_query([#("include", "items")])
    |> send(access_token)
  use res <- result.try(res)
  let body =
    res.body
    |> json.parse(json_api.json_api_response_decoder(
      included: tidal_types.playlist_decoder(),
      attribute: decode.dynamic,
    ))
    |> log_result(res)

  use payload <- result.try(body)
  case payload |> json_api.extract_included() {
    Some([json_api.ResourceObject(..), ..] as playlists) -> {
      playlists
      |> list.filter_map(fn(x) { x.attributes |> option.to_result(Nil) })
      |> Ok
    }
    _ -> Error(Nil)
  }
}

pub fn retrieve_self(access_token: String) -> Result(tidal_types.User, Nil) {
  let assert Ok(req) =
    uri.parse(user_self_endpoint) |> result.try(request.from_uri)

  let res = send(req, access_token)
  use res <- result.try(res)
  let body =
    res.body
    |> json.parse(json_api.json_api_response_decoder(
      included: decode.dynamic,
      attribute: tidal_types.user_decoder(),
    ))
    |> log_result(res)

  use payload <- result.try(body)
  case payload |> json_api.extract_data() {
    Some(json_api.One(json_api.ResourceObject(
      id: _,
      lid: _,
      type_: _,
      attributes: Some(self),
      relationships: _,
      links: _,
    ))) -> Ok(self)
    _ -> Error(Nil)
  }
}

fn send(req: request.Request(String), access_token: String) {
  req
  |> bearer_token.attach_bearer_token_string_to_header(access_token)
  |> httpc.send
  |> woof.log_error("Error while sending http request", [
    #("url", request.to_uri(req) |> uri.to_string()),
  ])
  |> result.map_error(fn(_) { Nil })
}

fn log_result(body, response: response.Response(String)) {
  case body {
    Ok(json_api.SuccessResponse(..)) ->
      woof.debug("Successfully requested user data", [#("body", response.body)])

    Ok(json_api.ErrorResponse(_, _, _, errors)) -> {
      errors
      |> list.index_map(format_error)
      |> list.flatten()
      |> woof.warning("Got error response", _)
    }

    Error(error) -> {
      woof.error("Unable to decode response", [#("payload", response.body)])
      echo error
      Nil
    }
  }
  body |> result.replace_error(Nil)
}

fn format_error(error: json_api.Error, i: Int) {
  let prefix = "error[" <> int.to_string(i) <> "]."
  [
    wrap_opt(prefix <> "title", error.title),
    wrap_opt(prefix <> "detail", error.detail),
    wrap_opt(prefix <> "id", error.id),
    wrap_opt(prefix <> "status", error.status),
    wrap_opt(prefix <> "code", error.code),
  ]
  |> list.filter_map(option.to_result(_, Nil))
}

fn wrap_opt(key: String, value: option.Option(String)) {
  value
  |> option.map(fn(v) { #(key, v) })
}
