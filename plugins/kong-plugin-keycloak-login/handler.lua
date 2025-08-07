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

  -- Read and decode request body
  ngx.req.read_body()
  local body = ngx.req.get_body_data() or ""
  local params = ngx.decode_args(body)

  -- Get client credentials from ENV
  local client_id = CLIENT_ID
  local client_secret = CLIENT_SECRET

  if not client_id or not client_secret then
    return kong.response.exit(500, { message = "Client credentials not configured in environment." })
  end

  -- Inject client credentials into body
  params["client_id"] = client_id
  params["client_secret"] = client_secret
  params["grant_type"] = "password"

  -- Re-encode and set the new body
  local new_body = ngx.encode_args(params)
  ngx.req.set_body_data(new_body)

  -- Update content length and make sure Content-Type is correct
  kong.service.request.set_header("content-length", #new_body)
  kong.service.request.set_header("content-type", "application/x-www-form-urlencoded")
end

return plugin

