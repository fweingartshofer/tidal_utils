import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/order
import gleam/result
import gleam/time/timestamp
import youid/uuid
import ywt

pub type TokenPayload {
  TokenPayload(uid: String, exp: timestamp.Timestamp)
}

pub fn decode_token(jwt: String) -> Result(TokenPayload, Nil) {
  let payload =
    jwt
    |> ywt.decode_unsafely_without_validation(tokens_payload_decoder())
  use payload <- result.try(payload)
  case timestamp.compare(timestamp.system_time(), payload.exp) {
    order.Lt -> Ok(payload)
    _ -> Error(Nil)
  }
}

fn tokens_payload_decoder() {
  use uid <- decode.field("uid", decode.int)
  use exp <- decode.field("exp", decode.int)
  decode.success(TokenPayload(
    uid |> int.to_string(),
    exp |> timestamp.from_unix_seconds(),
  ))
}

pub type TidalConnection {
  TidalConnection(
    id: uuid.Uuid,
    tidal_id: String,
    refresh_token: option.Option(String),
    access_token: option.Option(String),
    session_id: option.Option(String),
  )
}
