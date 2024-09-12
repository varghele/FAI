@echo off

set PROJECT_ID=fischerai
set ZONE=europe-west10-b
set ZONE_NAME=fischerai-dns-zone

:: Set GCP project
CALL gcloud config set project %PROJECT_ID%

echo Cleaning up resources in project: %PROJECT_ID%

:: List and delete all VM instances
for /f "tokens=*" %%i in ('gcloud compute instances list --format="value(name)"') do (
    echo Deleting VM instance: %%i
    gcloud compute instances delete %%i --zone=%ZONE% --quiet
)

:: List and delete all firewall rules
for /f "tokens=*" %%i in ('gcloud compute firewall-rules list --format="value(name)"') do (
    echo Deleting firewall rule: %%i
    gcloud compute firewall-rules delete %%i --quiet
)

:: List and delete all disks (in case there are detached disks left behind)
for /f "tokens=*" %%i in ('gcloud compute disks list --format="value(name)"') do (
    echo Deleting disk: %%i
    gcloud compute disks delete %%i --zone=%ZONE% --quiet
)

:: List and delete all static IPs (external IPs that are not automatically deleted)
for /f "tokens=*" %%i in ('gcloud compute addresses list --format="value(name)"') do (
    echo Releasing static IP: %%i
    gcloud compute addresses delete %%i --region=%ZONE% --quiet
)

:: List and delete all cloud storage buckets
for /f "tokens=*" %%i in ('gsutil ls') do (
    echo Deleting Cloud Storage bucket: %%i
    gsutil -m rm -r %%i
)

:: Delete the Cloud DNS zone
echo Deleting Cloud DNS zone %ZONE_NAME%...
gcloud dns managed-zones delete %ZONE_NAME% --quiet

echo Cloud DNS zone %ZONE_NAME% and its records have been deleted.

:: Optional: Delete other resources like networks or load balancers if applicable (TODO!)

echo Cleanup complete!
