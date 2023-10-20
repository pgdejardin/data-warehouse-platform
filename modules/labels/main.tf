locals {
  application    = lower(var.application)
  component      = lower(var.component)
  component_type = lower(var.component_type)
  environment    = lower(var.environment)
  owner          = lower(var.owner)

  label = format("%s-%s-%s-%s", local.application, local.environment, local.component, local.component_type)

  tags = {
    Name        = local.label
    Application = local.application
    Component   = local.component
    Environment = local.environment
    Owner       = local.owner
  }

  tags_ec2 = merge(local.tags, {})

  tags_asg = [
    for key, value in local.tags_ec2 : {
      key                 = key
      value               = value
      propagate_at_launch = true
    }
  ]
}
