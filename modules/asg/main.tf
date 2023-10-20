locals {}

module "autoscaling_labels" {
  source         = "../labels"
  application    = var.application
  component      = var.component
  component_type = "asg"
  environment    = var.environment
  owner          = "pgdejardin"
}

variable "min_size" {
  default = 0
}

variable "max_size" {
  default = 1
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "`EC2` or `ELB`. Controls how health checking is done"
  type        = string
  default     = "EC2"
}

variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start."
  default     = 300
}

variable "default_instance_warmup" {
  default = 0
}

variable "target_group_arns" {
  description = "To associate target group alb to autoscaling group"
  default     = []
}

variable "load_balancers" {
  description = "To associate target group classic load balancer to autoscaling group"
  default     = []
}

variable "wait_for_elb_capacity" {
  description = "wait for exactly this number of healthy instances to consider new/updated asg fully InService"
  default     = null
}

variable "wait_for_capacity_timeout" {
  default = null
}

variable "subnet_list" {
  default     = [""]
  description = "Subnet list across the asg is spanned"
}

variable "instance_refresh" {
  description = "If this block is configured, start an Instance Refresh when Auto Scaling Group is updated"
  type        = any
  default     = null
}

resource "aws_autoscaling_group" "asg" {
  name = "asg-${aws_launch_template.lt.name}"

  max_size = var.min_size
  min_size = var.max_size

  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  default_cooldown          = var.default_cooldown
  force_delete              = true
  default_instance_warmup   = var.default_instance_warmup

  target_group_arns         = var.target_group_arns
  load_balancers            = var.load_balancers
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  vpc_zone_identifier = var.subnet_list
  enabled_metrics     = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances", "GroupTerminatingInstances", "GroupPendingInstances"]
  metrics_granularity = "1Minute"

  launch_template {
    name    = aws_launch_template.lt.name
    version = aws_launch_template.lt.latest_version
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      triggers = lookup(instance_refresh.value, "triggers", null)

      dynamic "preferences" {
        for_each = lookup(instance_refresh.value, "preferences", null) != null ? [instance_refresh.value.preferences] : []
        content {
          instance_warmup        = lookup(preferences.value, "instance_warmup", null)
          min_healthy_percentage = lookup(preferences.value, "min_healthy_percentage", null)
          checkpoint_delay       = lookup(preferences.value, "checkpoint_delay", null)
          checkpoint_percentages = lookup(preferences.value, "checkpoint_percentages", null)
        }
      }
    }
  }

  tag = module.autoscaling_labels.tags_asg

  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "lt" {
  name_prefix = "lt-${module.autoscaling_labels.full_label}"
  tags        = module.autoscaling_labels.tags

  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data

  vpc_security_group_ids = length(var.network_interfaces) ? var.security_group_ids : []

  default_version                      = var.default_version
  update_default_version               = var.update_default_version
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  monitoring {
    enabled = var.monitoring_enabled
  }

  block_device_mappings {
    device_name = "/dev/xda"

    ebs {
      delete_on_termination = true
      encrypted             = var.root_volume_encrypted
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
    }
  }
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)

      dynamic "ebs" {
        for_each = flatten([lookup(block_device_mappings.value, "ebs", [])])
        content {
          delete_on_termination = lookup(ebs.value, "delete_on_termination", null)
          encrypted             = lookup(ebs.value, "encrypted", null)
          kms_key_id            = lookup(ebs.value, "kms_key_id", null)
          iops                  = lookup(ebs.value, "iops", null)
          throughput            = lookup(ebs.value, "throughput", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = lookup(capacity_reservation_specification.value, "capacity_reservation_preference", null)

      dynamic "capacity_reservation_target" {
        for_each = lookup(capacity_reservation_specification.value, "capacity_reservation_target", [])
        content {
          capacity_reservation_id = lookup(capacity_reservation_target.value, "capacity_reservation_id", null)
        }
      }
    }
  }

  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []
    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  dynamic "hibernation_options" {
    for_each = var.hibernation_options != null ? [var.hibernation_options] : []
    content {
      configured = hibernation_options.value.configured
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null || var.iam_instance_profile_arn != null ? [1] : []
    content {
      name = var.iam_instance_profile
      arn  = var.iam_instance_profile_arn
    }
  }

  dynamic "instance_market_options" {
    for_each = var.instance_market_options != null ? [var.instance_market_options] : []
    content {
      market_type = instance_market_options.value.market_type

      dynamic "spot_options" {
        for_each = lookup(instance_market_options.value, "spot_options", null) != null ? [instance_market_options.value.spot_options] : []
        content {
          block_duration_minutes         = spot_options.value.block_duration_minutes
          instance_interruption_behavior = lookup(spot_options.value, "instance_interruption_behavior", null)
          max_price                      = lookup(spot_options.value, "max_price", null)
          spot_instance_type             = lookup(spot_options.value, "spot_instance_type", null)
          valid_until                    = lookup(spot_options.value, "valid_until", null)
        }
      }
    }
  }

  dynamic "metadata_options" {
    for_each = var.metadata_options != null ? [var.metadata_options] : []
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", null)
      http_tokens                 = lookup(metadata_options.value, "http_tokens", null)
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", null)
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = module.autoscaling_labels.tags
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications
    content {
      resource_type = tag_specifications.value.resource_type
      tags          = tag_specifications.value.tags
    }
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_carrier_ip_address = lookup(network_interfaces.value, "associate_carrier_ip_address", null)
      associate_public_ip_address  = lookup(network_interfaces.value, "associate_public_ip_address", var.public_ip_address)
      delete_on_termination        = lookup(network_interfaces.value, "delete_on_termination", null)
      description                  = lookup(network_interfaces.value, "description", null)
      device_index                 = lookup(network_interfaces.value, "device_index", null)
      ipv4_addresses               = lookup(network_interfaces.value, "ipv4_addresses", null) != null ? network_interfaces.value.ipv4_addresses : []
      ipv4_address_count           = lookup(network_interfaces.value, "ipv4_address_count", null)
      ipv6_addresses               = lookup(network_interfaces.value, "ipv6_addresses", null) != null ? network_interfaces.value.ipv6_addresses : []
      ipv6_address_count           = lookup(network_interfaces.value, "ipv6_address_count", null)
      network_interface_id         = lookup(network_interfaces.value, "network_interface_id", null)
      private_ip_address           = lookup(network_interfaces.value, "private_ip_address", null)
      security_groups              = lookup(network_interfaces.value, "security_groups", null) != null ? network_interfaces.value.security_groups : var.security_groups_ids
      subnet_id                    = lookup(network_interfaces.value, "subnet_id", null)
    }
  }
}

resource "aws_autoscaling_schedule" "asg-scheduled-scaling-up" {
  count                  = var.scheduled_scaling_enabled ? 1 : 0
  scheduled_action_name  = "asg-scheduled-scaling-up-${module.autoscaling_labels.full_label}"
  min_size               = var.scheduled_scaling_min_size
  max_size               = "-1"
  desired_capacity       = "-1"
  recurrence             = var.scheduled_scaling_up_recurrence
  autoscaling_group_name = aws_autoscaling_group.asg.name
  time_zone              = var.timezone
}

resource "aws_autoscaling_schedule" "asg-scheduled-scaling-down" {
  count                  = var.scheduled_scaling_enabled ? 1 : 0
  scheduled_action_name  = "asg-scheduled-scaling-down-${module.autoscaling_labels.full_label}"
  min_size               = var.min_size
  max_size               = "-1"
  desired_capacity       = "-1"
  recurrence             = var.scheduled_scaling_down_recurrence
  autoscaling_group_name = aws_autoscaling_group.asg.name
  time_zone              = var.timezone
}

resource "aws_autoscaling_lifecycle_hook" "asg_hook" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  name                   = "hook-${module.autoscaling_labels.full_label}"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 120
}
