import os
import uuid  # For generating unique IDs
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


@app.route('/project1-1h1hnoesy', methods=['GET', 'POST'])
def project1():
    form = NOESYForm()  # Instantiate the form

    if form.validate_on_submit():
        try:
            # Generate a unique job ID for this submission
            job_id = str(uuid.uuid4())

            # Create a folder for this job in GCS (use the job_id as the folder name)
            job_folder = f"noesy_jobs/{job_id}/"

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
                    # Generate a custom filename and store it inside the job folder
                    custom_filename = f"{key}_{secure_filename(file.filename)}"
                    blob_name = f"{job_folder}{custom_filename}"  # Path in GCS

                    # Upload the file to GCP bucket and get the file URL
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
        # Generate a unique job ID for this submission
        job_id = str(uuid.uuid4())

        # Create a folder for this job in GCS (use the job_id as the folder name)
        job_folder = f"g2r_jobs/{job_id}/"

        # Handle the main molecule file upload
        molecule_file = form.moleculeFile.data
        if molecule_file:
            # Generate custom filename and store it inside the job folder
            molecule_filename = f"{job_folder}molecule_{secure_filename(molecule_file.filename)}"

            # Upload to GCP bucket and get the file URL
            molecule_file_url = upload_to_gcs(molecule_file, BUCKET_NAME, molecule_filename)
            flash(f'Molecule file uploaded: {molecule_file_url}', 'success')

        # Handle the secondary file upload if provided
        secondary_file = form.secondaryFile.data
        if secondary_file:
            # Generate custom filename and store it inside the job folder
            secondary_filename = f"{job_folder}secondary_{secure_filename(secondary_file.filename)}"

            # Upload to GCP bucket and get the file URL
            secondary_file_url = upload_to_gcs(secondary_file, BUCKET_NAME, secondary_filename)
            flash(f'Secondary file uploaded: {secondary_file_url}', 'success')

        # Redirect after successful upload
        flash(f'Job {job_id} submitted successfully!', 'success')
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
