output "full_label" { value = local.label }

output "tags" { value = merge(local.tags, var.tags) }
output "tags_ec2" { value = merge(local.tags_ec2, var.tags) }
output "tags_asg" { value = concat(local.tags_asg, var.tags_asg) }

output "application" { value = local.application }
output "component" { value = local.component }
output "component_type" { value = local.component_type }
output "environment" { value = local.environment }
output "owner" { value = local.owner }
