locals {
  superset_user_data = <<-EOT
    #!/bin/bash

    sudo dnf install -y gcc gcc-c++ libffi-devel python3-devel python3-pip python3-wheel openssl-devel cyrus-sasl-devel openldap-devel
    sudo dnf install https://rpm.nodesource.com/pub_18.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
    sudo dnf install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
    pip3 install --upgrade pip

    pip install apache-superset


    #### NE MARCHE PLUS

    superset db upgrade

    # Create an admin user in your metadata database (use `admin` as username to be able to load the examples)
    export FLASK_APP=superset
    superset fab create-admin

    # Load some data to play with
    superset load_examples

    # Create default roles and permissions
    superset init

    # Build javascript assets
    cd superset-frontend
    npm ci
    npm run build
    cd ..

    # To start a development web server on port 8088, use -p to bind to another port
    superset run -p 8088 --with-threads --reload --debugger
  EOT
}

module "superset_labels" {
  source         = "./modules/labels"
  application    = var.application
  component      = "superset"
  component_type = "ec2"
  environment    = var.environment
  owner          = var.owner
}

module "superset" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  depends_on = [module.clickhouse]

  name = module.superset_labels.full_label

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.medium" # used to set core count below
  availability_zone           = element(module.digipoc_vpc.azs, 0)
  subnet_id                   = element(module.digipoc_vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.allow_ssh_http_security_group.security_group_id]
  associate_public_ip_address = true
  disable_api_stop            = false

  key_name = var.key_pair_name

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies           = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  # only one of these can be enabled at a time
  hibernation = true
  # enclave_options_enabled = true

  user_data_base64            = base64encode(local.superset_user_data)
  user_data_replace_on_change = true

  #  cpu_options = {
  #    core_count       = 16
  #    threads_per_core = 2
  #  }

  enable_volume_tags = false
  root_block_device  = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 28
      tags        = {
        Name = "root-volume"
      }
    },
  ]

#  ebs_block_device = [
#    {
#      device_name = "/dev/sdf"
#      volume_type = "gp3"
#      volume_size = 8
#      throughput  = 200
#      encrypted   = true
#      kms_key_id  = aws_kms_key.superset_kms.arn
#      tags        = {
#        MountPoint = "/mnt/data"
#      }
#    }
#  ]

  tags = module.superset_labels.tags
}

#resource "aws_kms_key" "superset_kms" {}
