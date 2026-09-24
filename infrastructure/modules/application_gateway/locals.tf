locals {
  backend_address_pool_name      = "${var.app_gateway_name}-backend-pool"
  frontend_port_name             = "${var.app_gateway_name}-frontend-port"
  frontend_ip_configuration_name = "${var.app_gateway_name}-frontend-ip"
  http_setting_name              = "${var.app_gateway_name}-http-settings"
  listener_name                  = "${var.app_gateway_name}-listener"
  request_routing_rule_name      = "${var.app_gateway_name}-routing-rule"
  health_probe_name              = "${var.app_gateway_name}-health-probe"
  ssl_certificate_name           = "${var.app_gateway_name}-ssl-cert"
}

