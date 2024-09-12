@echo off

:: Set variables
set PROJECT_ID=fischerai
set ZONE=europe-west10-b ::BERLIN
set INSTANCE_NAME=nginx-main
set MACHINE_TYPE=e2-micro
set GITHUB_REPO=https://github.com/varghele/FAI.git
set STARTUP_SCRIPT_PATH=nginx-startup.sh

:: Set GCP project
CALL gcloud config set project %PROJECT_ID%

:: Create a new VM instance
CALL gcloud compute instances create %INSTANCE_NAME% ^
    --zone=%ZONE% ^
    --machine-type=%MACHINE_TYPE% ^
    --tags=tag-nginx-main ^
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default ^
    --maintenance-policy=MIGRATE ^
    --provisioning-model=STANDARD ^
    --service-account=506359823535-compute@developer.gserviceaccount.com ^
    --create-disk=auto-delete=yes,boot=yes,device-name=instance-20240912-055812,image=projects/debian-cloud/global/images/debian-12-bookworm-v20240910,mode=rw,size=10,type=pd-balanced ^
    --no-shielded-secure-boot ^
    --shielded-vtpm ^
    --shielded-integrity-monitoring ^
    --labels=goog-ec-src=vm_add-gcloud ^
    --reservation-affinity=any ^
    --metadata-from-file startup-script=%STARTUP_SCRIPT_PATH% ^
    --metadata GITHUB_REPO=%GITHUB_REPO%

:: Allow HTTP traffic (port 80)
CALL gcloud compute firewall-rules create niginx-allow-http ^
    --allow=tcp:80 ^
    --target-tags=tag-nginx-main ^
    --description="Allow HTTP traffic on port 80"

:: Output the external IP of the instance
for /f "tokens=*" %%i in ('gcloud compute instances describe %INSTANCE_NAME% --zone=%ZONE% --format="get(networkInterfaces[0].accessConfigs[0].natIP)"') do set EXTERNAL_IP=%%i
echo Nginx is running. Access the website at: http://%EXTERNAL_IP%
