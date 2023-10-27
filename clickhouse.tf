#module "instance_profile" {
#  source          = "./modules/instance_profile"
#  application     = var.application
#  component       = "clickhouse"
#  component_type  = "instance_profile"
#  environment     = var.environment
#  owner           = var.owner
#  policy_template = data.aws_iam_policy_document.instance_policy.json
#  account_id      = data.aws_caller_identity.current.account_id
#}
#
#
#module "clickhouse" {
#  source               = "./modules/asg"
#  iam_instance_profile = module.instance_profile.profile_name
#  user_data            = data.cloudinit_config.cloud_init.rendered
#
#  ami           = data.aws_ami.base_ami.id
#  instance_type = var.clickhouse_instance_type
#
#  security_group_ids = []
#  subnet_list = module.digipoc_vpc.private_subnets
#
#  health_check_type = "EC2"
#  min_size = "1"
#  max_size = "1"
#
#  key_name = "aws_${var.environment}"
#
#  wait_for_elb_capacity = 0
#
#  root_volume_size = var.
#}
#
#data "aws_ami" "base_ami" {
#  most_recent = true
#  owners      = ["amazon"]
#
#  filter {
#    name   = "name"
#    values = ["al2023-ami-2023.*-x86_64"]
#  }
#
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#
#}
#
#data "template_file" "init" {
#  template = file("./templates/user-data.sh.tpl")
#  vars     = {
#    environment = var.environment
#    component   = "template_file_init"
#    region      = var.region
#  }
#}
#
#data "cloudinit_config" "cloud_init" {
#  gzip = true
#
#  part {
#    content_type = "text/x-shellscript"
#    content      = data.template_file.init.rendered
#  }
#}
#
#data "aws_iam_policy_document" "instance_policy" {
#  statement {
#    effect  = "Allow"
#    actions = [
#      "autoscaling:DescribeAutoScalingGroups",
#      "autoscaling:UpdateAutoScalingGroup"
#    ]
#    resources = [
#      "arn:aws:autoscaling:${var.region}:*:autoScalingGroup:*:autoScalingGroupName/*clickhouse*"
#    ]
#  }
#}

locals {
  clickhouse_user_data = <<-EOT
    #!/bin/bash

    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo
    sudo yum install -y clickhouse-server clickhouse-client
    sudo systemctl enable clickhouse-server
    sudo systemctl start clickhouse-server
    sudo systemctl status clickhouse-server
  EOT
}

module "clickhouse_labels" {
  source         = "./modules/labels"
  application    = var.application
  component      = "clickhouse"
  component_type = "ec2"
  environment    = var.environment
  owner          = var.owner
}

module "clickhouse" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name = module.clickhouse_labels.full_label

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

  user_data_base64            = base64encode(local.clickhouse_user_data)
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
      volume_size = 300
      tags = {
        Name = "root-volume"
      }
    },
  ]

#  ebs_block_device = [
#    {
#      device_name = "/dev/sdf"
#      volume_type = "gp3"
#      volume_size = 500
#      throughput  = 200
#      encrypted   = true
#      iops        = 4500
#      kms_key_id  = aws_kms_key.clickhouse_kms.arn
#      tags = {
#        MountPoint = "/mnt/data"
#      }
#    }
#  ]

  tags = module.clickhouse_labels.tags
}

#resource "aws_kms_key" "clickhouse_kms" {}
