# SonarQube Terraform Install

This Terraform configuration provisions an AWS EC2 instance and installs SonarQube using remote-exec provisioners, based on the provided Ansible playbook.

## Variables

- `region`: AWS region (default: eu-west-1)
- `ports`: List of ports to open in security group (default: [22, 9000])
- `instance_type`: EC2 instance type (default: t2.small)
- `sonarqube_version`: SonarQube version to install (default: 9.9.3.79811)
- `sonarqube_user`: User to run SonarQube as (default: sonar)
- `sonarqube_group`: Group for SonarQube user (default: sonar)
- `sonarqube_install_dir`: Directory to download zip (default: /opt)
- `sonarqube_dir`: Directory to install SonarQube (default: /opt/sonarqube)

## Usage

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Plan the deployment:
   ```
   terraform plan
   ```

3. Apply the configuration:
   ```
   terraform apply
   ```

4. Access SonarQube at `http://<public_ip>:9000`

## Outputs

- `public_ip`: Public IP of the SonarQube server
- `private_ip`: Private IP of the SonarQube server