import os
from flask import Flask, request, render_template, redirect, url_for, flash
from werkzeug.utils import secure_filename
from google.cloud import storage

# Initialize the Flask application
app = Flask(__name__)
# Load secret key from environment variable
# Generate a random secret key
app.secret_key = os.urandom(24)

if not app.secret_key:
    raise ValueError("No FLASK_SECRET_KEY set for Flask application")

# Google Cloud Storage bucket name
BUCKET_NAME = 'your-gcs-bucket-name'

# Initialize Google Cloud Storage client
storage_client = storage.Client()


def upload_to_gcs(file, bucket_name, destination_blob_name):
    """Uploads a file to Google Cloud Storage."""
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_file(file)
    return blob.public_url


@app.route('/')
def index():
    """Render the main form."""
    return render_template('index.html')


@app.route('/submit-noesy-data', methods=['POST'])
def submit_noesy_data():
    """Handle the submission of the NOESY analysis form."""

    try:
        # Get the form data
        membrane_type = request.form['membraneType']
        peaks_order = request.form['peaksOrder']
        display_order = request.form['displayOrder']
        chemical_name = request.form['chemicalName']
        ppm_values = request.form['ppmValues']

        # Check for file uploads
        files = {
            '0ms': request.files['integratedValues0ms'],
            '100ms': request.files['integratedValues100ms'],
            '200ms': request.files['integratedValues200ms'],
            '300ms': request.files['integratedValues300ms'],
            '500ms': request.files['integratedValues500ms']
        }

        # Loop over the files and upload them to GCS
        uploaded_file_urls = {}
        for key, file in files.items():
            if file:
                filename = secure_filename(file.filename)
                blob_name = f"{chemical_name}/{key}/{filename}"
                file_url = upload_to_gcs(file, BUCKET_NAME, blob_name)
                uploaded_file_urls[key] = file_url

        # Flash a success message (or handle as you like)
        flash('Data submitted successfully!')

        # Return the success page or redirect
        return redirect(url_for('index'))

    except Exception as e:
        flash(f'An error occurred: {str(e)}')
        return redirect(url_for('index'))


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
