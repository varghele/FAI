@echo off

:: Set variables
set PROJECT_ID=fischerai
set REGION=europe-west10
set ZONE=europe-west10-b
set ZONE_NAME=fischerai-dns-zone
set INSTANCE_NAME=nginx-main
set MACHINE_TYPE=e2-micro
set BUCKET_NAME=fischerai-1h1hnoesy-bucket
set GITHUB_REPO=https://github.com/varghele/FAI.git
set STARTUP_SCRIPT_PATH=nginx-beta.sh

:: Set GCP project
CALL gcloud config set project %PROJECT_ID%

:: Create the bucket with public access protection (no object versioning)
CALL gcloud storage buckets create gs://%BUCKET_NAME% --location=%REGION% --public-access-prevention --default-storage-class=STANDARD
:: Optional: Enable uniform bucket-level access (optional)
:: CALL gcloud storage buckets update gs://%BUCKET_NAME% --uniform-bucket-level-access

echo Bucket %BUCKET_NAME% created successfully without object versioning (soft delete recovery) and public access protection enabled.

:: Set up DNS zone for dynamic routing
CALL gcloud dns --project=%PROJECT_ID% managed-zones create %ZONE_NAME% --description="" --dns-name="fischerai.com." --visibility="public" --dnssec-state="off"

:: Create a new VM instance
CALL gcloud compute instances create %INSTANCE_NAME% ^
    --zone=%ZONE% ^
    --machine-type=%MACHINE_TYPE% ^
    --tags=tag-nginx-main ^
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default ^
    --maintenance-policy=MIGRATE ^
    --provisioning-model=STANDARD ^
    --service-account=fischerai-1h1hnoesy-fileupload@fischerai.iam.gserviceaccount.com ^
    --scopes=https://www.googleapis.com/auth/cloud-platform ^
    --create-disk=auto-delete=yes,boot=yes,device-name=instance-20240912-055812,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240910,mode=rw,size=10,type=pd-balanced ^
    --no-shielded-secure-boot ^
    --shielded-vtpm ^
    --shielded-integrity-monitoring ^
    --labels=goog-ec-src=vm_add-gcloud ^
    --reservation-affinity=any ^
    --metadata-from-file startup-script=%STARTUP_SCRIPT_PATH% ^
    --metadata GITHUB_REPO=%GITHUB_REPO%

:: Allow HTTP traffic (port 80)
CALL gcloud compute firewall-rules create nginx-allow-http ^
    --allow=tcp:80 ^
    --target-tags=tag-nginx-main ^
    --description="Allow HTTP traffic on port 80"

:: Allow TCP ingress (port 22)
CALL gcloud compute firewall-rules create nginx-allow-ssh-tcp ^
    --allow=tcp:22 ^
    --target-tags=tag-nginx-main ^
    --description="Allow TCP traffic on port 22"

:: Output the external IP of the instance
for /f "tokens=*" %%i in ('gcloud compute instances describe %INSTANCE_NAME% --zone=%ZONE% --format="get(networkInterfaces[0].accessConfigs[0].natIP)"') do set EXTERNAL_IP=%%i
echo Nginx is running. Access the website at: http://%EXTERNAL_IP%
