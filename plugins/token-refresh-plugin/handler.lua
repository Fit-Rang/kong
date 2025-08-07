local kong = kong
local ngx = ngx

local CLIENT_ID = os.getenv("KONG_CLIENT_ID")
local CLIENT_SECRET = os.getenv("KONG_CLIENT_SECRET")

local plugin = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

function plugin.access(self, conf)
  local content_type = kong.request.get_header("content-type")

  if not content_type or not content_type:match("application/x%-www%-form%-urlencoded") then
    return kong.response.exit(415, { message = "Unsupported Media Type. Expecting x-www-form-urlencoded." })
  end

  ngx.req.read_body()
  local body = ngx.req.get_body_data() or ""
  local params = ngx.decode_args(body)

  if not params["refresh_token"] then
    return kong.response.exit(400, { message = "Missing refresh_token in request body." })
  end

  if not CLIENT_ID or not CLIENT_SECRET then
    return kong.response.exit(500, { message = "Client credentials not configured in environment." })
  end

  params["client_id"] = CLIENT_ID
  params["client_secret"] = CLIENT_SECRET
  params["grant_type"] = "refresh_token"

  local new_body = ngx.encode_args(params)
  ngx.req.set_body_data(new_body)

  kong.service.request.set_header("content-length", #new_body)
  kong.service.request.set_header("content-type", "application/x-www-form-urlencoded")
end

return plugin

