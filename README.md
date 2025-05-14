# My-VPN

This project provides a simple Flask-based server to manage and retrieve VPN client configuration files.

## Prerequisites

- Ubuntu/Debian-based system
- Python 3.x installed
- `pip` for Python package management

## Setup Instructions

1. Clone the repository:
    ```bash
    git clone <repository-url>
    cd My-VPN
    ```

2. Run the setup script to install dependencies:
    ```bash
    ./setup.sh
    ```

3. Install Python dependencies:
    ```bash
    pip install flask
    ```


4. Start the server with `SECRET_KEY`:
    ```bash
    SECRET_KEY=<your_key> python3 server.py
    ```

## Usage

1. Ensure the server is running on `http://0.0.0.0:5000`.

2. To download a VPN client configuration file, make a GET request to the `/conf` endpoint with the following query parameters:
    - `key`: The secret key set in the `SECRET_KEY` environment variable.
    - `idx`: The index of the client configuration file (e.g., `1` for `client1.conf`).

    Example:
    ```bash
    curl -O "http://<server-ip>:5000/conf?key=<your-secret-key>&name=<idx-of-conf-file>"
    ```

3. The server will return the requested configuration file if the key is valid and the file exists. Otherwise:
    - A `403 Forbidden` error is returned for an invalid key.
    - A `404 Not Found` error is returned if the file does not exist.

4. To add new client, run this command with `sudo`:
    ```bash
    ./add_client --client-name <name>
    ```

## Notes

- Ensure the VPN client configuration files are stored in `/etc/wireguard/clients/` with the naming convention `client<idx>.conf`.
- Run the server in a secure environment and restrict access to authorized users only.
- To create QR from a config file, run this command:
```bash
sudo cat /etc/wireguard/clients/<client_name>.conf | qrencode -t ansiutf8
```
## License

This project is licensed under the MIT License.  
