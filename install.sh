#!/bin/bash

# --- Configuration ---
INSTALL_DIR="$HOME/.local/share/PyWebServer"
SERVICE_NAME="PyWebServer"
PYTHON_VENV_DIR="$INSTALL_DIR/venv"
FLASK_APP_FILE="PyWebServer.py"
STARTUP_SCRIPT="$INSTALL_DIR/$SERVICE_NAME.sh"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}@.service"

# --- Detect OS and Install Dependencies ---
echo "Detecting OS and installing dependencies..."

if grep -q "Ubuntu" /etc/os-release; then
    echo "Detected Ubuntu. Installing python3-venv..."
    sudo apt update
    sudo apt install -y python3-venv || { echo "Failed to install python3-venv. Exiting."; exit 1; }
elif grep -q "Arch Linux" /etc/os-release; then
    echo "Detected Arch Linux. Installing python-virtualenv..."
    sudo pacman -Syu --noconfirm python-virtualenv || { echo "Failed to install python-virtualenv. Exiting."; exit 1; }
else
    echo "Unsupported operating system. This script supports Ubuntu and Arch Linux."
    exit 1
fi

# --- Create Installation Directory and Copy Files ---
echo "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR" || { echo "Failed to create directory $INSTALL_DIR. Exiting."; exit 1; }

echo "Copying PyWebServer files to $INSTALL_DIR..."
# Assuming PyWebServer.py and README.md are in the same directory as the install script or accessible
# For this example, we'll simulate copying the provided content directly within the script.
# In a real scenario, you'd copy from the source location, e.g., cp PyWebServer.py "$INSTALL_DIR/"

# Create PyWebServer.py
cat <<EOF > "$INSTALL_DIR/$FLASK_APP_FILE"
# app.py

from flask import Flask, render_template

# Initialize the Flask application
app = Flask(__name__)

# Define a route for the home page.
# When a user accesses the root URL ("/"), this function will be called.
@app.route('/')
def home():
    """
    Renders the 'index.html' template when the home page is accessed.
    """
    return render_template('index.html')

# This block ensures that the Flask development server runs only when
# the script is executed directly (e.g., python app.py)
if __name__ == '__main__':
    # Run the Flask app in debug mode.
    # debug=True allows for automatic reloading on code changes
    # and provides a debugger in the browser.
    # host='0.0.0.0' makes the server accessible from external IPs.
    app.run(debug=True, host='0.0.0.0')
EOF
echo "Created $INSTALL_DIR/$FLASK_APP_FILE"

# Create README.md
cat <<EOF > "$INSTALL_DIR/README.md"
# PyWebServer
Deploy a basic HTML webserver with ease using flask
EOF
echo "Created $INSTALL_DIR/README.md"

# --- Setup Python Virtual Environment ---
echo "Setting up Python virtual environment in $PYTHON_VENV_DIR..."
python3 -m venv "$PYTHON_VENV_DIR" || { echo "Failed to create virtual environment. Exiting."; exit 1; }

echo "Activating virtual environment and installing Flask..."
source "$PYTHON_VENV_DIR/bin/activate" || { echo "Failed to activate virtual environment. Exiting."; exit 1; }
pip install flask || { echo "Failed to install Flask. Exiting."; exit 1; }
deactivate
echo "Flask installed."

# --- Create Startup Script ---
echo "Creating startup script: $STARTUP_SCRIPT"
cat <<EOF > "$STARTUP_SCRIPT"
#!/bin/bash
# Activate the Python virtual environment
source "$PYTHON_VENV_DIR/bin/activate"
# Start the Flask application
exec python "$INSTALL_DIR/$FLASK_APP_FILE"
EOF
chmod +x "$STARTUP_SCRIPT" || { echo "Failed to make $STARTUP_SCRIPT executable. Exiting."; exit 1; }
echo "Startup script created and made executable."

# --- Create Systemd Service File ---
echo "Creating systemd service file: $SYSTEMD_SERVICE_FILE"
sudo bash -c "cat <<EOF > \"$SYSTEMD_SERVICE_FILE\"
[Unit]
Description=$SERVICE_NAME service for %i
After=network.target

[Service]
User=%i
ExecStart=$STARTUP_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF" || { echo "Failed to create systemd service file. Exiting."; exit 1; }
echo "Systemd service file created."

# --- Enable and Start Systemd Service ---
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload || { echo "Failed to reload systemd daemon. Exiting."; exit 1; }

echo "Enabling and starting $SERVICE_NAME service for user $(whoami)..."
sudo systemctl enable "${SERVICE_NAME}@$(whoami)" || { echo "Failed to enable service. Exiting."; exit 1; }
sudo systemctl start "${SERVICE_NAME}@$(whoami)" || { echo "Failed to start service. Exiting."; exit 1; }

echo "Installation complete. PyWebServer should now be running."
echo "You can check its status with: sudo systemctl status ${SERVICE_NAME}@$(whoami)"
