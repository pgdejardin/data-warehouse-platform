module "alb_labels" {
  source         = "./modules/labels"
  application    = var.application
  component      = ""
  component_type = "alb"
  environment    = var.environment
  owner          = var.owner
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name               = module.alb_labels.label
  load_balancer_type = "application"

  vpc_id  = module.digipoc_vpc.vpc_id
  subnets = module.digipoc_vpc.public_subnets

  security_groups      = [module.digipoc_vpc.default_security_group_id]
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP"
      cidr_blocks = ["0.0.0.0/0"]
    },
    ingress_all_mysql = {
      type        = "ingress"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Allow Mysql Access"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_all_mongodb = {
      type        = "ingress"
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      description = "Allow MongoDB Access"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_all_icmp = {
      type        = "ingress"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "ICMP"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port               = 3306
      protocol           = "HTTP"
      target_group_index = 0
      # action_type        = "forward"
    },
    {
      port               = 27017
      protocol           = "HTTP"
      target_group_index = 1
      # action_type        = "forward"
    },
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 2
      # action_type        = "forward"
    },
  ]

  target_groups = [
    {
      name_prefix                       = "mysql-"
      backend_protocol                  = "HTTP"
      backend_port                      = 3306
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      health_check                      = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 10
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-499"
      }
      protocol_version = "HTTP1"
      targets          = {
        mysql = {
          target_id = module.ingestion.id
          port      = 3306
        }
      }
      tags = {
        InstanceTargetGroupTag = "ingestion"
      }
    },
    {
      name_prefix                       = "mongo-"
      backend_protocol                  = "HTTP"
      backend_port                      = 27017
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      health_check                      = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 10
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-499"
      }
      protocol_version = "HTTP1"
      targets          = {
        mongo = {
          target_id = module.ingestion.id
          port      = 27017
        }
      }
      tags = {
        InstanceTargetGroupTag = "ingestion"
      }
    },
    {
      name_prefix                       = "sset-"
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      health_check                      = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 10
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-499"
      }
      protocol_version = "HTTP1"
      targets          = {
        mongo = {
          target_id = module.superset.id
          port      = 8088
        }
      }
      tags = {
        InstanceTargetGroupTag = "ingestion"
      }
    },
  ]
}

output "alb_dns" {
  value = module.alb.lb_dns_name
}
