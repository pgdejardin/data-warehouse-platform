module "sg_ssh_http_labels" {
  source         = "./modules/labels"
  application    = var.application
  component      = "allow-ssh-http"
  component_type = "sg"
  environment    = var.environment
  owner          = var.owner
}

module "allow_ssh_http_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = module.sg_ssh_http_labels.full_label
  description = "Security group for example usage with EC2 instance"
  vpc_id      = module.digipoc_vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp", "ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = module.sg_ssh_http_labels.tags
}
