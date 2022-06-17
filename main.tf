provider "aws" {
  region = local.region
}

locals {
  name   = "Nginx demo"
  region = "eu-central-1"

  user_data = <<-EOT
  #!/bin/bash
  echo "Hello Terraform!"
  EOT

  tags = {
    Terraform   = "true"
    Name = "nginx nap"
    demo_name = "Nginx"
    owner = "dborovyk"
  }
}


################################################################################
# Supporting Resources
################################################################################



################################################################################
# Module for NGINX NAP
################################################################################


module "nginx_nap" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "nginx-app-protect-minimum"

  ami                    = "ami-02584c1c9d05efa69"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  monitoring             = true
  vpc_security_group_ids = var.sec_group
  subnet_id              = var.subnet

 

  user_data = <<-EOF
        #!/bin/bash
        sudo apt-get update
        sudo dpkg --configure -a
        sudo apt-get install -y apt-transport-https lsb-release ca-certificates wget gnupg2 net-tools iputils-ping dnsutils sudo vim curl telnet unzip
        sudo mkdir -p /etc/ssl/nginx 

        # !!! NGINX Lic have to be download, unziped and moved tgo /etc/ssl/nginx folder at this stage
        # !!! You can use "wget", "unzip"/"untar" and "mv" tools for that 
        
        sudo wget https://cs.nginx.com/static/keys/nginx_signing.key && sudo apt-key add nginx_signing.key
        sudo wget https://cs.nginx.com/static/keys/app-protect-security-updates.key && sudo apt-key add app-protect-security-updates.key
        sudo apt-get install apt-transport-https lsb-release ca-certificates
        printf "deb https://pkgs.nginx.com/plus/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list
        printf "deb https://pkgs.nginx.com/app-protect/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-app-protect.list
        printf "deb https://pkgs.nginx.com/app-protect-security-updates/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee -a /etc/apt/sources.list.d/nginx-app-protect.list
        sudo wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90pkgs-nginx
        sudo apt-get update
        sudo apt-get install -y nginx-plus
        sudo apt-get install app-protect app-protect-attack-signatures
        
  EOF

  tags = {
    Terraform   = "true"
    Name = "nginx nap"
    demo_name = "Nginx"
    owner = "dborovyk"
  }
}

################################################################################
# Module for NGINX Controller
################################################################################


resource "aws_instance" "controller" {
  ami                  = "ami-09356619876445425"
  #iam_instance_profile = aws_iam_instance_profile.iam_nginx_profile.id
  instance_type        = "t2.2xlarge"
  root_block_device {
    volume_size = "80"
  }
  associate_public_ip_address = true
  #availability_zone           = var.aws_az
  subnet_id                   = var.subnet
  vpc_security_group_ids      = var.sec_group
  key_name                    = var.key_name

  user_data = <<-EOF
      #!/bin/bash
      apt-get update
      swapoff -a
      ufw disable
      apt-get install jq socat conntrack -y
      
      # !!! NGINX Controller Image have to be download, unziped and moved to /etc/ssl/nginx folder at this stage
      # !!! You can use "wget", "unzip"/"untar" and "mv" tools for that 

      wget https://sorinnginx.s3.eu-central-1.amazonaws.com/controller-installer-3.7.0.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
     
      # !!! Next lines have to be modified according your installation
     
      /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@example.com --fqdn $host_ip --organization-name nginx --admin-firstname your_firstname --admin-lastname your_lastname --admin-email your_email --admin-password your_password --self-signed-cert --auto-install-docker --tsdb-volume-type local
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "your_username","password": "your_password"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"Your lic is here"}'
    EOF

  tags = {
    Name = "controller"
    demo_name = "Nginx"
    owner = "dborovyk"
  }
}
