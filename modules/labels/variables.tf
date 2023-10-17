variable "application" {
  type        = string
  description = "Application name"
}

variable "component" {
  type        = string
  description = "Component name"
}

variable "component_type" {
  type        = string
  description = "Component type (asg, alb, vpc, etc.)"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prd, etc.)"
}

variable "owner" {
  type        = string
  description = "Owner of the resource"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}

variable "tags_asg" {
  type = list(object({
    key               = string
    value             = string
    propage_at_launch = bool
  }))
  description = "Additional tag list to apply on AutoScaling Group.\nDefault: []"
  default     = []
}
