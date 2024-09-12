@echo off
setlocal enabledelayedexpansion

:: Access the parent directory of the batch file location
set PARENT_DIR=%~dp0..
pushd %PARENT_DIR%
set PARENT_DIR=%CD%
popd
echo %PARENT_DIR%

:: Set the directory where the Terraform configuration and tfvars file are located
set TF_DIR=%PARENT_DIR%\terra\
set TFVARS_FILE=%PARENT_DIR%\terra\fai_main.tfvars

:: Change to the Terraform directory
cd /d %TF_DIR%

:: Initialize Terraform
echo Initializing Terraform...
call terraform init
if errorlevel 1 (
    echo Terraform initialization failed! Exiting...
    exit /b 1
)

:: Plan the Terraform execution (creates an execution plan using the tfvars file)
echo Planning Terraform execution...
call terraform plan -out=tfplan -var-file=%TFVARS_FILE%
if errorlevel 1 (
    echo Terraform plan failed! Exiting...
    exit /b 1
)

:: Apply the Terraform plan (creates the infrastructure using the tfvars file)
echo Applying the Terraform plan...
call terraform apply -auto-approve tfplan
if errorlevel 1 (
    echo Terraform apply failed! Exiting...
    exit /b 1
)

:: Cleanup the Terraform plan file
del tfplan

:: Success message
echo Terraform apply complete. All resources created successfully.
pause
