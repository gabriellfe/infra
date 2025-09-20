output "rabbit_password" {
  value     = module.rabbit.rabbit_password
  sensitive = false
}

output "admin_password" {
  value     = module.rabbit.admin_password
  sensitive = false
}
