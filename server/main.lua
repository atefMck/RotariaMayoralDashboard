-- City Info Server Main File

-- Version Information
local VERSION = "1.0.0"

local Accounts = require("accounts")
local Plots = require("plots")
local CityInfo = require("cityinfo")
local Protocol = require("protocol")

local modem = peripheral.find("modem") or error("No modem attached", 0)
local SERVER_CHANNEL = 100
local CLIENT_CHANNEL = 200

-- Initialize Server
print("=== Rotaria City Server Starting ===")
print("Computer ID: " .. os.getComputerID())
print("Opening channels " .. SERVER_CHANNEL .. " (server) and " .. CLIENT_CHANNEL .. " (client)")

modem.open(SERVER_CHANNEL)
modem.open(CLIENT_CHANNEL)
Accounts.load()
Plots.load()
CityInfo.load()

-- Create default admin account if it doesn't exist
local defaultAdmin = Accounts.findByUsername("Rotaria City")
if not defaultAdmin then
    print("Creating default admin account...")
    local success, result = Accounts.create("Rotaria City", "Rotaria!0!", "admin")
    if success then
        print("Default admin account created: Rotaria City")
    else
        print("Warning: Failed to create default admin account: " .. tostring(result))
    end
else
    print("Default admin account already exists")
end

print("Server ready. Listening on channel " .. SERVER_CHANNEL)
print("Commands:")
print("  - create_account: Create a new account (admin or citizen)")
print("  - login: Login to an existing account")
print("  - get_all_users: Get all users (admin only)")
print("  - create_plot_application: Submit a plot application")
print("  - get_plot_applications: Get pending plot applications (admin only)")
print("  - update_plot_status: Approve/reject plot application (admin only)")
print("  - get_city_info: Get city information")
print("  - update_city_info: Update city information (admin only)")
print("")

-- Event Loop
while true do
    local success, err = pcall(function()
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == SERVER_CHANNEL then
            print("Received message on channel " .. channel .. " from reply channel " .. replyChannel)
            Protocol.processMessage(channel, replyChannel, message, distance, modem)
        end
    end)
    
    if not success then
        print("Error occurred: " .. tostring(err))
        -- Continue running the server even if there's an error
    end
end

