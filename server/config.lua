-- Configuration Module
local Config = {}

-- Define and load channel settings
settings.define("mayor.server_channel", {
    description = "Server communication channel",
    default = 100,
    type = "number"
})

settings.define("mayor.client_channel", {
    description = "Client communication channel",
    default = 200,
    type = "number"
})

settings.load()

-- Global constants
SERVER_CHANNEL = settings.get("mayor.server_channel") or 100
CLIENT_CHANNEL = settings.get("mayor.client_channel") or 200

return Config

