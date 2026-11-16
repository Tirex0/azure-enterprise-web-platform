package terraform.security

# Public IP → Standard SKU kötelező
deny contains msg if {
	some pip in input.resource_changes

	pip.type == "azurerm_public_ip"
	pip.change.after.sku != "Standard"

	msg := sprintf(
		"%s uses a non-Standard SKU",
		[pip.address],
	)
}

# NSG → ne legyen engedélyezve az Internet felől a TCP 22-es port
public_source_prefixes := {"Internet", "*", "0.0.0.0/0", "::/0"}

is_public_source(rule) if {
	rule.source_address_prefix in public_source_prefixes
}

is_public_source(rule) if {
	some source in object.get(rule, "source_address_prefixes", [])
	source in public_source_prefixes
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

	msg := sprintf(
		"%s allows inbound SSH access from the Internet",
		[nsg.address],
	)
}

# NSG → ne legyen Allow minden címről érkező inbound szabály
any_source_prefixes := {"*", "0.0.0.0/0", "::/0"}

is_any_source(rule) if {
	rule.source_address_prefix in any_source_prefixes
}

is_any_source(rule) if {
	some source in object.get(rule, "source_address_prefixes", [])
	source in any_source_prefixes
}

deny contains msg if {
	some nsg in input.resource_changes
	nsg.type == "azurerm_network_security_group"

	some rule in nsg.change.after.security_rule

	rule.access == "Allow"
	rule.direction == "Inbound"
	is_any_source(rule)

	msg := sprintf(
		"%s allows inbound access from any source",
		[nsg.address],
	)
}

# VMSS → password authentication legyen letiltva
deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some vmss in module.resources

	vmss.type == "azurerm_linux_virtual_machine_scale_set"
	vmss.values.disable_password_authentication == false

	msg := sprintf(
		"%s allows password authentication, which is prohibited.",
		[vmss.address],
	)
}

# Log Analytics Workspace → internet query access ne legyen engedélyezve
deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some workspace in module.resources

	workspace.type == "azurerm_log_analytics_workspace"
	workspace.values.internet_query_access_type == "Enabled"

	msg := sprintf(
		"%s resource has internet_query_access_type Enabled",
		[workspace.address],
	)
}

# Log Analytics Workspace → retention legyen több mint 30 nap
deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some workspace in module.resources

	workspace.type == "azurerm_log_analytics_workspace"
	workspace.values.retention_in_days <= 30

	msg := sprintf(
		"%s Log Analytics Workspace has a retention in days limit below 31",
		[workspace.address],
	)
}

# Application Gateway → a listener ne használjon HTTP-t
deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some appgw in module.resources
	some listener in appgw.values.http_listener

	appgw.type == "azurerm_application_gateway"
	listener.protocol == "Http"

	msg := sprintf(
		"%s listener does not use HTTPS",
		[appgw.address],
	)
}

# Subnet → ne legyen engedélyezve a default outbound access
deny contains msg if {
	some module in input.planned_values.root_module.child_modules
	some subnet in module.resources

	subnet.type == "azurerm_subnet"
	subnet.values.default_outbound_access_enabled == true

	msg := sprintf(
		"%s subnet has default outbound access enabled set to true",
		[subnet.address],
	)
}
