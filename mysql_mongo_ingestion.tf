
locals {
  ingestion_user_data = <<-EOT
    #!/bin/bash

    ### MongoDB ###
    cat <<EOF > /etc/yum.repos.d/mongodb-org-7.0.repo
    [mongodb-org-7.0]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
    EOF

    sudo yum install -y mongodb-org
    sudo systemctl enable mongod
    sudo systemctl start mongod
    sudo systemctl status mongod

    ### MYSQL ###
    sudo rpm -Uvh https://repo.mysql.com/mysql80-community-release-el9-4.noarch.rpm
    sudo sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
    sudo yum --enablerepo=mysql80-community install -y mysql-community-server
    sudo systemctl enable mysqld
    sudo systemctl start mysqld
    sudo systemctl status mysqld
  EOT
}

module "ingestion_labels" {
  source         = "./modules/labels"
  application    = var.application
  component      = "ingestion"
  component_type = "ec2"
  environment    = var.environment
  owner          = var.owner
}

module "ingestion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name = module.ingestion_labels.full_label

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "c5.xlarge" # used to set core count below
  availability_zone           = element(module.digipoc_vpc.azs, 0)
  subnet_id                   = element(module.digipoc_vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.allow_ssh_http_security_group.security_group_id]
  placement_group             = aws_placement_group.cluster.id
  associate_public_ip_address = true
  disable_api_stop            = false

  key_name = var.key_pair_name

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  # only one of these can be enabled at a time
  hibernation = true
  # enclave_options_enabled = true

  user_data_base64            = base64encode(local.ingestion_user_data)
  user_data_replace_on_change = true

  #  cpu_options = {
  #    core_count       = 16
  #    threads_per_core = 2
  #  }

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
      tags = {
        Name = "root-volume"
      }
    },
  ]

  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 500
      throughput  = 200
      encrypted   = true
      iops        = 4500
      kms_key_id  = aws_kms_key.ingestion_kms.arn
      tags = {
        MountPoint = "/mnt/data"
      }
    }
  ]

  tags = module.ingestion_labels.tags
}

resource "aws_kms_key" "ingestion_kms" {}
