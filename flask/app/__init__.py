from flask import Flask
from flask_wtf.csrf import CSRFProtect

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'  # This is needed for securely handling forms

# CSRF protection for forms
csrf = CSRFProtect(app)

# Import the routes module to register routes
from app import routes
