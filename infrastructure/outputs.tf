output "workload_nat_public_ip" {
  description = "Stable outbound IP used by the web and application subnets."
  value       = module.networking.workload_nat_public_ip
}

output "application_gateway_public_ip" {
  description = "Public IPv4 address used by the Application Gateway HTTPS listener."
  value       = module.application_gateway.public_ip_address
}
