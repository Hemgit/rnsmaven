# Nexus Terraform Install

This Terraform configuration provisions an AWS EC2 instance and installs Nexus Repository Manager using remote-exec provisioners.

## Variables

- `region`: AWS region (default: eu-west-1)
- `ports`: List of ports to open in security group (default: [22, 8081])
- `instance_type`: EC2 instance type (default: t2.small)
- `nexus_version`: Nexus version to install (default: 3.70.1-02)
- `nexus_user`: User to run Nexus as (default: nexus)
- `nexus_group`: Group for Nexus user (default: nexus)
- `nexus_install_dir`: Directory to download tarball (default: /opt)
- `nexus_dir`: Directory to install Nexus (default: /opt/nexus)
- `nexus_data_dir`: Data directory (default: /opt/sonatype-work)

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

4. Access Nexus at `http://<public_ip>:8081`

## Outputs

- `public_ip`: Public IP of the Nexus server
- `private_ip`: Private IP of the Nexus server