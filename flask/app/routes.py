import os
from flask import render_template, redirect, url_for, flash, request
from app import app
from app.forms import NOESYForm, G2RForm  # Correct import path
from werkzeug.utils import secure_filename
from google.cloud import storage

# Google Cloud Storage bucket name
BUCKET_NAME = 'fischerai-1h1hnoesy-bucket'

# Initialize Google Cloud Storage client
storage_client = storage.Client()

# Function to upload a file to Google Cloud Storage
def upload_to_gcs(file, bucket_name, destination_blob_name):
    """Uploads a file to Google Cloud Storage and returns the public URL."""
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_file(file)
    return blob.public_url

# Route for the index page
@app.route('/')
@app.route('/index')
def index():
    return render_template("index.html")


# Route for the NOESY data submission page
@app.route('/project1-1h1hnoesy', methods=['GET', 'POST'])
def project1():
    form = NOESYForm()  # Instantiate the form

    if form.validate_on_submit():
        try:
            # Get form data
            membrane_type = form.membraneType.data
            peaks_order = form.peaksOrder.data
            display_order = form.displayOrder.data
            chemical_name = form.chemicalName.data
            ppm_values = form.ppmValues.data

            # Handle file uploads for different mixing times
            files = {
                '0ms': request.files['integratedValues0ms'],
                '100ms': request.files['integratedValues100ms'],
                '200ms': request.files['integratedValues200ms'],
                '300ms': request.files['integratedValues300ms'],
                '500ms': request.files['integratedValues500ms']
            }

            # Dictionary to store uploaded file URLs
            uploaded_file_urls = {}

            # Loop through the files, upload to GCS, and assign specific filenames
            for key, file in files.items():
                if file:
                    # Generate a custom filename
                    custom_filename = f"{chemical_name}_{key}_{secure_filename(file.filename)}"
                    blob_name = f"{chemical_name}/{key}/{custom_filename}"  # Path in GCS

                    # Upload the file to GCS
                    file_url = upload_to_gcs(file, BUCKET_NAME, blob_name)
                    uploaded_file_urls[key] = file_url

            # Redirect to the processing page with the file URLs
            return redirect(url_for('processing', file_urls=uploaded_file_urls))

        except Exception as e:
            # Flash an error message if something goes wrong
            flash(f'An error occurred: {str(e)}', 'danger')
            return redirect(url_for('project1'))

    # Render the template with the form
    return render_template('project1-1h1hnoesy.html', form=form)


@app.route('/project2-g2r', methods=['GET', 'POST'])
def project2():
    form = G2RForm()  # Instantiate the form

    # If the form is submitted and passes validation
    if form.validate_on_submit():
        # Handle the form submission
        flash('Data submitted successfully!', 'success')
        return redirect(url_for('project2'))

    # Render the template with the form passed as a variable
    return render_template('project2-g2r.html', form=form)


# Route for processing page with spinner
@app.route('/processing')
def processing():
    # Get file URLs from the request query parameters
    file_urls = request.args.get('file_urls')

    # Render the spinner page and simulate a delay
    return render_template('processing.html', file_urls=file_urls)


# Route for the result page with download links
@app.route('/results')
def results():
    # Get file URLs from the request query parameters
    file_urls = request.args.get('file_urls', {})

    # Convert the file_urls back into a dictionary (as it comes through the URL query string as a string)
    if isinstance(file_urls, str):
        import ast
        file_urls = ast.literal_eval(file_urls)

    # Render the results page with the file URLs
    return render_template('results.html', file_urls=file_urls)


# Route for the about page
@app.route('/about')
def about():
    return render_template('about.html')
