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

1. Run the server installer:
   ```bash
   lua installServer.lua
   ```

   Or for quick install:
   ```bash
   lua installServer.lua -q
   ```

2. The installer will:
   - Copy server files to the installation directory (default: `cityServer`)
   - Configure encryption and password settings (same as CogMail)
   - Optionally set up automatic startup

3. Start the server:
   ```bash
   cd cityServer
   lua main.lua
   ```

### Client Installation

1. Run the client installer:
   ```bash
   lua installClient.lua
   ```

   Or for quick install:
   ```bash
   lua installClient.lua -q
   ```

2. The installer will:
   - Copy client files to the installation directory (default: `cityClient`)
   - Optionally set up automatic startup

3. Start the client:
   ```bash
   cd cityClient
   lua main.lua
   ```

## Configuration

### Server Settings

The server uses the same settings as CogMail for encryption and password hashing:

```lua
settings.set("email.encryption_key", "your_custom_encryption_key")
settings.set("email.password_salt", "your_custom_password_salt")
settings.save()
```

Or using the `set` program:
```
set email.encryption_key your_custom_key
set email.password_salt your_custom_salt
```

**Important**: Change these from the defaults for security!

## Usage

### Creating Accounts

1. Start the client
2. Click "Create Account"
3. Enter username and password
4. Select account type (Citizen or Admin)
5. Click "Create Account"

### Citizen Features

- **Info**: View city information
- **Plot Application**: Submit a plot application with:
  - In-game name
  - Plot number/location
  - Build description
  - Estimated size & style
  - Reason for wanting the plot

### Admin Features

- **All Users**: View list of all registered users
- **Plot Applications**: Review pending plot applications
  - View application details
  - Accept or reject applications

## File Structure

```
RotariaMayoralDashboard/
├── server/
│   ├── encryption.lua      # Encryption/decryption module
│   ├── accounts.lua         # Account management
│   ├── plots.lua            # Plot applications management
│   ├── cityinfo.lua         # City information management
│   ├── protocol.lua         # Network protocol handler
│   └── main.lua             # Server entry point
├── client/
│   ├── network.lua          # Network communication
│   ├── utils.lua            # Utility functions
│   ├── main.lua             # Client entry point
│   ├── components/
│   │   └── header.lua       # Header component
│   └── screens/
│       ├── login.lua        # Login screen
│       ├── account_creation.lua
│       ├── citizen_dashboard.lua
│       ├── mayor_dashboard.lua
│       ├── info.lua
│       ├── plot_application.lua
│       ├── user_list.lua
│       └── plot_review.lua
├── installServer.lua
├── installClient.lua
└── README.md
```

## Security

- Passwords are hashed using salted hashing (same algorithm as CogMail)
- All sensitive data (plots, city info) is encrypted on disk
- Authentication is required for all endpoints
- Admin-only endpoints verify account type

## Network Protocol

- **Server Channel**: 100
- **Client Channel**: 200
- All communication uses ComputerCraft's modem system

## Troubleshooting

### Client can't connect to server
- Ensure server is running
- Check that both computers have modems attached
- Verify network connectivity

### Basalt not found
- Install Basalt2: `wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/refs/heads/main/release/basalt-full.lua basalt.lua`
- Or place basalt.lua in the client directory

### Authentication errors
- Verify encryption keys match between server and client
- Check that account exists and password is correct

## License

This project follows the same structure and security practices as CogMail.

