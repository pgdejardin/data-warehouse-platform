output "full_label" { value = local.label }

output "tags" { value = merge(local.tags, var.tags) }
output "tags_ec2" { value = merge(local.tags_ec2, var.tags) }
output "tags_asg" { value = merge(local.tags_ec2, var.tags_asg) }
