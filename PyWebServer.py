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
