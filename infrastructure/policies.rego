package terraform.security

public_source_prefixes := {"Internet", "*", "0.0.0.0/0", "::/0"}
any_source_prefixes := {"*", "0.0.0.0/0", "::/0"}

deny contains msg if {
	some pip in input.resource_changes
	pip.type == "azurerm_public_ip"
	object.get(pip.change.after, "sku", "") != "Standard"
	msg := sprintf("%s uses a non-Standard SKU", [pip.address])
}

is_public_source(rule) if {
	object.get(rule, "source_address_prefix", "") in public_source_prefixes
}

is_public_source(rule) if {
	some source in object.get(rule, "source_address_prefixes", [])
	source in public_source_prefixes
}

is_any_source(rule) if {
	object.get(rule, "source_address_prefix", "") in any_source_prefixes
}

is_any_source(rule) if {
	some source in object.get(rule, "source_address_prefixes", [])
	source in any_source_prefixes
}

port_contains_ssh(port) if {
	port == "22"
}

port_contains_ssh(port) if {
	port == "*"
}

port_contains_ssh(port) if {
	regex.match("^[0-9]+-[0-9]+$", port)
	bounds := split(port, "-")
	to_number(bounds[0]) <= 22
	to_number(bounds[1]) >= 22
}

rule_contains_ssh_port(rule) if {
	port_contains_ssh(object.get(rule, "destination_port_range", ""))
}

rule_contains_ssh_port(rule) if {
	some port in object.get(rule, "destination_port_ranges", [])
	port_contains_ssh(port)
}

deny contains msg if {
	some nsg in input.resource_changes
	nsg.type == "azurerm_network_security_group"
	some rule in nsg.change.after.security_rule
	rule.access == "Allow"
	rule.direction == "Inbound"
	rule.protocol in {"Tcp", "*"}
	is_public_source(rule)
	rule_contains_ssh_port(rule)
	msg := sprintf("%s allows inbound SSH access from the Internet", [nsg.address])
}

deny contains msg if {
	some nsg in input.resource_changes
	nsg.type == "azurerm_network_security_group"
	some rule in nsg.change.after.security_rule
	rule.access == "Allow"
	rule.direction == "Inbound"
	is_any_source(rule)
	msg := sprintf("%s allows inbound access from any source", [nsg.address])
}

deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some vm in module.resources
	vm.type in {"azurerm_linux_virtual_machine", "azurerm_linux_virtual_machine_scale_set"}
	object.get(vm.values, "disable_password_authentication", false) != true
	msg := sprintf("%s allows password authentication, which is prohibited", [vm.address])
}

deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some workspace in module.resources
	workspace.type == "azurerm_log_analytics_workspace"
	object.get(workspace.values, "internet_query_access_type", "Enabled") != "Disabled"
	msg := sprintf("%s has Log Analytics internet query access enabled", [workspace.address])
}

deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some workspace in module.resources
	workspace.type == "azurerm_log_analytics_workspace"
	object.get(workspace.values, "retention_in_days", 0) <= 30
	msg := sprintf("%s Log Analytics Workspace retention must be greater than 30 days", [workspace.address])
}

deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some appgw in module.resources
	some listener in appgw.values.http_listener
	appgw.type == "azurerm_application_gateway"
	listener.protocol != "Https"
	msg := sprintf("%s listener does not use HTTPS", [appgw.address])
}

is_application_gateway_subnet(subnet) if {
	contains(subnet.address, "[\"app_gateway\"]")
}

deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some subnet in module.resources
	subnet.type == "azurerm_subnet"
	not is_application_gateway_subnet(subnet)
	object.get(subnet.values, "default_outbound_access_enabled", null) != false
	msg := sprintf("%s workload subnet must disable default outbound access", [subnet.address])
}
