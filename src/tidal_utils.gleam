import dream/servers/mist/server.{bind, context, listen, router, services}
import gleam/io
import gleam/option
import tidal_utils/router
import tidal_utils/services
import tidal_utils/tidal_auth_context
import woof

pub fn main() -> Nil {
  woof.set_level(woof.Info)
  case services.new() {
    Ok(res) -> {
      server.new()
      |> services(res)
      |> context(tidal_auth_context.TidalAuthContext("", option.None))
      |> router(router.create_router())
      |> bind("localhost")
      |> listen(3000)
      Nil
    }
    Error(error) -> {
      io.print_error("Could not initialize required services tables")
      echo error
      Nil
    }
  }
}
