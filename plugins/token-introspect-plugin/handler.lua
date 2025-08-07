local http = require "resty.http"
local cjson = require "cjson.safe"

local kong = kong
local ngx = ngx

local CLIENT_ID = os.getenv("KONG_CLIENT_ID")
local CLIENT_SECRET = os.getenv("KONG_CLIENT_SECRET")
local INTROSPECT_URL = "http://keycloak:8080/realms/FitRang/protocol/openid-connect/token/introspect"

local plugin = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

function plugin.access(self, conf)
  local auth_header = kong.request.get_header("Authorization")

  if not auth_header or not auth_header:match("^Bearer%s+") then
    return kong.response.exit(401, { message = "Missing or invalid Authorization header" })
  end

  local token = auth_header:match("^Bearer%s+(.+)$")

  if not CLIENT_ID or not CLIENT_SECRET then
    return kong.response.exit(500, { message = "Client credentials not set in environment." })
  end

  if not INTROSPECT_URL then
    return kong.response.exit(500, { message = "Introspection URL not set in environment." })
  end

  local httpc = http.new()
  httpc:set_timeout(5000)

  local res, err = httpc:request_uri(INTROSPECT_URL, {
    method = "POST",
    body = "token=" .. ngx.escape_uri(token),
    headers = {
      ["Content-Type"] = "application/x-www-form-urlencoded",
      ["Authorization"] = "Basic " .. ngx.encode_base64(CLIENT_ID .. ":" .. CLIENT_SECRET)
    },
    ssl_verify = false,
  })

  if not res then
    kong.log.err("Failed to introspect token: ", err)
    return kong.response.exit(401, { message = "Token validation failed" })
  end

  local body, decode_err = cjson.decode(res.body)
  if not body then
    kong.log.err("Failed to decode Keycloak response: ", decode_err)
    return kong.response.exit(500, { message = "Invalid response from authorization server" })
  end

  if not body.active then
    return kong.response.exit(401, { message = "Token is invalid or expired" })
  end

  if body.sub then
    kong.service.request.set_header("X-User", body.sub)
  end
  if body.name then
    kong.service.request.set_header("X-Name", body.name)
  end
end

return plugin

