# Rotaria City Info System

A complete city information and plot application system for ComputerCraft using Basalt2 and CC Tweaked. Features secure authentication, encrypted data storage, and a beautiful GUI interface.

## Features

- **Secure Authentication**: Hashed passwords and encrypted data storage
- **Account Types**: Admin and Citizen accounts with different permissions
- **City Information**: View and manage city information (admin only)
- **Plot Applications**: Citizens can apply for plots, admins can review and approve/reject
- **User Management**: Admins can view all registered users
- **Dynamic UI**: Responsive layouts that adapt to screen size
- **Beautiful Interface**: Modern Basalt2-based GUI with Rotaria City branding

## Requirements

- ComputerCraft (CC Tweaked)
- Basalt2 GUI framework
- Wireless or Wired Modem (for server-client communication)

## Installation

### Server Installation

1. Download and run the server installer:
   ```bash
   wget https://raw.githubusercontent.com/atefMck/RotariaMayoralDashboard/refs/heads/main/installServer.lua installServer.lua
   installServer.lua
   ```

2. Or use quick install mode:
   ```bash
   installServer.lua -q
   ```

3. Start the server:
   ```bash
   local server = require("rotariaServer")
   server.runServer()
   ```

   Or create a startup file:
   ```bash
   echo 'local server = require("rotariaServer"); server.runServer()' > startup.lua
   ```

### Mayor Client Installation

1. Download and run the mayor client installer:
   ```bash
   wget https://raw.githubusercontent.com/atefMck/RotariaMayoralDashboard/refs/heads/main/installClientMayor.lua installClientMayor.lua
   installClientMayor.lua
   ```

2. Or use quick install mode:
   ```bash
   installClientMayor.lua -q
   ```

3. Start the mayor client:
   ```bash
   local client = require("rotariaClientMayor")
   client.runClient()
   ```

   Or create a startup file:
   ```bash
   echo 'local client = require("rotariaClientMayor"); client.runClient()' > startup.lua
   ```

### Citizen Client Installation

1. Download and run the citizen client installer:
   ```bash
   wget https://raw.githubusercontent.com/atefMck/RotariaMayoralDashboard/refs/heads/main/installClientCitizen.lua installClientCitizen.lua
   installClientCitizen.lua
   ```

2. Or use quick install mode:
   ```bash
   installClientCitizen.lua -q
   ```

3. Start the citizen client:
   ```bash
   local client = require("rotariaClientCitizen")
   client.runClient()
   ```

   Or create a startup file:
   ```bash
   echo 'local client = require("rotariaClientCitizen"); client.runClient()' > startup.lua
   ```

## Initial Mayor Account

When the server starts for the first time, it automatically creates a default mayor (admin) account:

- **Username**: `Rotaria`
- **Password**: `Rotaria`

**Important**: Change this password immediately after first login for security!

You can use this account to:
- Create additional mayor accounts
- Manage all mayor accounts
- Review and approve/reject plot applications
- Create and manage city information tabs

## Configuration

### Server Settings

The server uses settings for encryption and password hashing:

```lua
settings.set("mayor.encryption_key", "your_custom_encryption_key")
settings.set("mayor.password_salt", "your_custom_password_salt")
settings.save()
```

Or using the `set` program:
```
set mayor.encryption_key your_custom_key
set mayor.password_salt your_custom_salt
```

**Important**: Change these from the defaults for security!

## Usage

### Mayor (Admin) Features

- **Create Mayor Account**: Create additional mayor accounts
- **All Mayor Accounts**: View and manage all mayor accounts (can delete accounts)
- **Plot Applications**: Review pending plot applications
  - View application details
  - Accept or reject applications
- **Info Tabs**: Create and manage city information tabs
  - Create new tabs
  - Edit existing tabs
  - Delete tabs

### Citizen Features

- **Info**: View city information tabs (no login required)
- **Plot Application**: Submit a plot application with:
  - In-game name
  - Plot number/location
  - Build description
  - Estimated size & style
  - Reason for wanting the plot
  - (No login required)

## Network Protocol

- **Server Channel**: 100
- **Client Channel**: 200
- All communication uses ComputerCraft's modem system

## License

This project follows the same structure and security practices as CogMail.
