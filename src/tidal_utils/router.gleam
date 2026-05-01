import dream/http/request.{Get}
import dream/router.{route, router}
import tidal_utils/middlewares/layout_middleware
import tidal_utils/middlewares/logging_middleware
import tidal_utils/middlewares/session_id_middleware
import tidal_utils/middlewares/tidal_auth_middleware
import tidal_utils/pages/callback
import tidal_utils/pages/home
import tidal_utils/services
import tidal_utils/tidal_auth_context.{type TidalAuthContext}

pub fn create_router() -> router.Router(TidalAuthContext, services.Services) {
  router()
  |> route(method: Get, path: "/", controller: home.render, middleware: [
    session_id_middleware.handle,
    tidal_auth_middleware.handle,
    layout_middleware.after_handler,
    logging_middleware.handle,
  ])
  |> route(
    method: Get,
    path: "/callback",
    controller: callback.render,
    middleware: [
      session_id_middleware.handle,
      tidal_auth_middleware.handle,
      layout_middleware.after_handler,
      logging_middleware.handle,
    ],
  )
}
