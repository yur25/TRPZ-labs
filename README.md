# Laboratory Work №1: Deployment of a Web Service with Automation

## Personal Variant
- **Number (N):** 26
- **V2 = 1:** Configuration via command-line arguments. Database: MariaDB.
- **V3 = 3:** Service type: **Simple Inventory** (equipment accounting).
- **V5 = 2:** Application listens on port **5200**.
- **Application Name:** `mywebapp`

## Project Architecture
This project is a complete Linux deployment of a Node.js web service involving:
- **Nginx:** Reverse proxy listening on `0.0.0.0:80`, routing traffic to the Node.js app.
- **Node.js & Express:** The API listening on `127.0.0.1:5200`.
- **Systemd:** Manages the Node.js application process (`mywebapp.service`), running it as a dedicated system user. Ensures DB migrations run before the app starts.
- **MariaDB:** Relational database storing the inventory items.

## Project Structure
```text
mywebapp-lab/
├── app/                    # Node.js source code
│   ├── migrations/
│   │   └── migrate.js      # DB Migration script (Idempotent)
│   ├── src/
│   │   ├── config.js       # CLI arguments parser (yargs)
│   │   ├── db.js           # MariaDB connection pool
│   │   └── server.js       # Express Web App
│   └── package.json        
├── nginx/                  
│   └── mywebapp.conf       # Nginx reverse proxy configuration
├── systemd/                
│   ├── mywebapp.service    # Systemd service unit
│   └── socket-activation/  # Optional upgrade resources
│       ├── mywebapp.socket
│       └── mywebapp.service
├── scripts/                
│   └── setup.sh            # One-click deployment script
└── README.md               # Project documentation
```

## How to Deploy (Automation)

The entire infrastructure can be set up automatically on a fresh Debian/Ubuntu system using the provided bash script. 

1. Clone or copy this repository to the target Linux server.
2. Make the setup script executable:
   ```bash
   chmod +x scripts/setup.sh
   ```
3. Run the script as `root` (or with sudo):
   ```bash
   sudo ./scripts/setup.sh
   ```

The setup script will:
- Install all necessary packages (Node.js, MariaDB, Nginx).
- Create the application database.
- Configure users and roles (`student`, `teacher`, `mywebapp`, `operator`).
- Deploy the app to `/opt/mywebapp`.
- Install, configure, and start the systemd service and nginx.

## User Accounts
As requested, the following OS users are configured:
- `student` & `teacher`: Full system access (sudo). Password initialized to `12345678` with a forced reset on first login.
- `mywebapp`: No-login system account with minimal rights, only used to run the Node.js process.
- `operator`: Restricted user. Allowed to run `sudo systemctl {start|stop|restart|status} mywebapp` and `sudo nginx -s reload` / `sudo systemctl reload nginx` without entering a root password. Default password `12345678` (forced reset on first login).

## API & Testing Instructions

The API supports **Content Negotiation**. It will return raw `JSON` to programmatic clients (like `curl` or Postman) and clean HTML pages for browsers (when `Accept: text/html` is sent).

### 1. View Root and Endpoints
**HTML:** Open `http://localhost/` in a browser.
**JSON:** `curl -H "Accept: application/json" http://localhost/`

### 2. View Inventory
**HTML:** Open `http://localhost/items` in a browser.
**JSON:** `curl -H "Accept: application/json" http://localhost/items`

### 3. Create an Item
**HTML:** Submit the form located at the root `http://localhost/` URL.
**JSON:** `curl -X POST -H "Content-Type: application/json" -d '{"name":"Oscilloscope", "quantity": 5}' http://localhost/items`

### 4. Get Item Details
**HTML:** Open `http://localhost/items/1` in a browser.
**JSON:** `curl -H "Accept: application/json" http://localhost/items/1`

### 5. Health Checks
- **Liveness:** `curl http://localhost/health/alive` (Always returns 200 OK)
- **Readiness:** `curl http://localhost/health/ready` (Returns 200 OK if DB connects, else 500)

## Systemd Socket Activation (Upgrade)
To upgrade from standard Systemd execution to Socket Activation:
1. Copy `systemd/socket-activation/mywebapp.socket` and `systemd/socket-activation/mywebapp.service` completely replacing the existing `/etc/systemd/system/mywebapp.service`.
2. Reload daemons: `sudo systemctl daemon-reload`.
3. Stop the service: `sudo systemctl stop mywebapp.service`.
4. Enable and start the socket: `sudo systemctl enable --now mywebapp.socket`.
5. The Node.js application will dynamically parse `LISTEN_FDS` and bind correctly upon the first incoming request hitting Nginx.
