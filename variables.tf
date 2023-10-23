variable "region" {
  default = "eu-west-1"
  type    = string
}

variable "environment" {
  default = "dev"
  type    = string
}

variable "application" {
  default = "digipoc"
  type    = string
}

variable "owner" {
  default = "pgdejardin"
  type    = string
}


### Clickhouse ###

variable "clickhouse_instance_type" {
  default = "c5.large"
}

variable "key_pair_name" {
  default = "aws_digipoc"
}
