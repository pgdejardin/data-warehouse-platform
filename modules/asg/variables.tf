variable "application" {
  default     = ""
  description = "Application Name"
}

variable "component" {
  default     = ""
  description = "Component Name"
}

variable "environment" {
  default     = ""
  description = "Environment name"
}

##########
### LT ###
##########

variable "ami" {
  default     = ""
  description = "AMI ID to deploy"
}
variable "instance_type" {
  default     = "t2.micro"
  description = "Instance type"
}
variable "key_name" {
  default     = "aws"
  description = "key name to use to connect to instance"
}
variable "user_data" {
  description = "User data"
}

variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(any)
  default     = []
}

variable "security_group_ids" {
  default     = []
  description = "Security Group list"
}

variable "default_version" {
  description = "Default Version of the launch template"
  type        = string
  default     = null
}

variable "update_default_version" {
  description = "Whether to update Default Version each update. Conflicts with `default_version`"
  type = string
  default = null
}

variable "disable_api_termination" {
  description = "If true, enables EC2 Instance termination protection"
  type = bool
  default = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance. Can be `stop` or `terminate`. (Default: `stop`)"
  type = string
  default = "stop"
}

variable "monitoring_enabled" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = false
}

variable "root_volume_encrypted" {
  description = "Enables root volume encryption"
  type = bool
  default = false
}

variable "root_volume_size" {
  description = "Root volume size"
  type        = string
  default     = "8"
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volume specified by the AMI"
  type = list(any)
  default = []
}


variable "capacity_reservation_specification" {
  description = "Targeting for EC2 capacity reservations"
  type        = any
  default     = null
}

variable "credit_specification" {
  description = "Customize the credit specification of the instance"
  type        = map(string)
  default     = null
}

variable "hibernation_options" {
  description = "The hibernation options for the instance"
  type        = map(string)
  default     = null
}

variable "iam_instance_profile" {
  description = "Instance profile (role)"
  type        = any
}

variable "iam_instance_profile_arn" {
  description = "The IAM instance profile ARN to launch the instance with"
  type        = string
  default     = null
}

variable "instance_market_options" {
  description = "The market (purchasing) option for the instance"
  type        = any
  default     = null
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type        = map(string)
  default     = null
}

variable "tag_specifications" {
  description = "The tags to apply to the resources during launch"
  type        = list(any)
  default     = []
}

variable "public_ip_address" {
  default = false
}

###############
### Scaling ###
###############

variable "scheduled_scaling_enabled" {
  description = "Specify if a scheduled scaling is needed"
  default     = false
}

variable "scheduled_scaling_min_size" {
  description = "Number of minimum running instances during scheduled scaling"
  default     = ""
}

variable "scheduled_scaling_down_recurrence" {
  description = "Unix cron syntax format specifying when a scheduled down-scaling starts"
  default     = ""
}

variable "scheduled_scaling_up_recurrence" {
  description = "Unix cron syntax format specifying when a scheduled up-scaling starts"
  default     = ""
}

variable "timezone" {
  description = "timezone for scheduled autoscaling cron"
  default     = "UTC"
}
