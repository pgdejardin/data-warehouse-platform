module "placement_labels" {
  source         = "./modules/labels"
  application    = var.application
  component      = "placement-cluster"
  component_type = "ec2"
  environment    = var.environment
  owner          = var.owner
}

resource "aws_placement_group" "cluster" {
  name     = module.placement_labels.full_label
  strategy = "cluster"
}

