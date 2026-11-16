package policy_test

import data.terraform.security as security

test_nonstandard_public_ip_is_denied if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "azurerm_public_ip.test",
			"type": "azurerm_public_ip",
			"change": {"after": {"sku": "Basic"}},
		}],
	}

	result == {"azurerm_public_ip.test uses a non-Standard SKU"}
}

test_standard_public_ip_is_allowed if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "azurerm_public_ip.test",
			"type": "azurerm_public_ip",
			"change": {"after": {"sku": "Standard"}},
		}],
	}

	count(result) == 0
}

test_inbound_ssh_from_internet_is_denied if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "azurerm_network_security_group.test",
			"type": "azurerm_network_security_group",
			"change": {
				"after": {
					"security_rule": [{
						"access": "Allow",
						"direction": "Inbound",
						"protocol": "Tcp",
						"source_address_prefix": "Internet",
						"destination_port_range": "22",
					}],
				},
			},
		}],
	}

	result == {"azurerm_network_security_group.test allows inbound SSH access from the Internet"}
}

test_inbound_allow_from_anywhere_is_denied if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "azurerm_network_security_group.test",
			"type": "azurerm_network_security_group",
			"change": {
				"after": {
					"security_rule": [{
						"access": "Allow",
						"direction": "Inbound",
						"source_address_prefix": "*",
					}],
				},
			},
		}],
	}

	result == {"azurerm_network_security_group.test allows inbound access from any source"}
}

test_password_authentication_is_denied if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "azurerm_linux_virtual_machine_scale_set.test",
						"type": "azurerm_linux_virtual_machine_scale_set",
						"values": {"disable_password_authentication": false},
					}],
				}],
			},
		},
	}

	result == {"azurerm_linux_virtual_machine_scale_set.test allows password authentication, which is prohibited"}
}

test_linux_virtual_machine_password_authentication_is_denied if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.compute.azurerm_linux_virtual_machine.app_vm",
						"type": "azurerm_linux_virtual_machine",
						"values": {"disable_password_authentication": false},
					}],
				}],
			},
		},
	}

	result == {"module.compute.azurerm_linux_virtual_machine.app_vm allows password authentication, which is prohibited"}
}

test_log_analytics_public_query_is_denied if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "azurerm_log_analytics_workspace.test",
						"type": "azurerm_log_analytics_workspace",
						"values": {
							"internet_query_access_type": "Enabled",
							"retention_in_days": 90,
						},
					}],
				}],
			},
		},
	}

	result == {"azurerm_log_analytics_workspace.test has Log Analytics internet query access enabled"}
}

test_log_analytics_short_retention_is_denied if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "azurerm_log_analytics_workspace.test",
						"type": "azurerm_log_analytics_workspace",
						"values": {
							"internet_query_access_type": "Disabled",
							"retention_in_days": 30,
						},
					}],
				}],
			},
		},
	}

	result == {"azurerm_log_analytics_workspace.test Log Analytics Workspace retention must be greater than 30 days"}
}

test_application_gateway_http_listener_is_denied if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.application_gateway.azurerm_application_gateway.network",
						"type": "azurerm_application_gateway",
						"values": {"http_listener": [{"protocol": "Http"}]},
					}],
				}],
			},
		},
	}

	result == {"module.application_gateway.azurerm_application_gateway.network listener does not use HTTPS"}
}

test_workload_subnet_default_outbound_is_denied if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.networking.azurerm_subnet.subnets[\"web_subnet\"]",
						"type": "azurerm_subnet",
						"values": {"default_outbound_access_enabled": true},
					}],
				}],
			},
		},
	}

	result == {"module.networking.azurerm_subnet.subnets[\"web_subnet\"] workload subnet must disable default outbound access"}
}

test_gateway_managed_subnet_keeps_platform_egress_policy if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.networking.azurerm_subnet.subnets[\"app_gateway\"]",
						"type": "azurerm_subnet",
						"values": {"default_outbound_access_enabled": null},
					}],
				}],
			},
		},
	}

	count(result) == 0
}

test_ssh_range_and_wildcard_protocol_are_denied if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "module.networking.azurerm_network_security_group.web",
			"type": "azurerm_network_security_group",
			"change": {
				"after": {
					"security_rule": [{
						"access": "Allow",
						"direction": "Inbound",
						"protocol": "*",
						"source_address_prefixes": ["0.0.0.0/0"],
						"destination_port_ranges": ["1000-1024", "20-22"],
					}],
				},
			},
		}],
	}

	result == {
		"module.networking.azurerm_network_security_group.web allows inbound SSH access from the Internet",
		"module.networking.azurerm_network_security_group.web allows inbound access from any source",
	}
}

test_any_source_in_prefix_list_is_denied if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "module.networking.azurerm_network_security_group.web",
			"type": "azurerm_network_security_group",
			"change": {
				"after": {
					"security_rule": [{
						"access": "Allow",
						"direction": "Inbound",
						"protocol": "Tcp",
						"source_address_prefixes": ["::/0"],
						"destination_port_ranges": ["443"],
					}],
				},
			},
		}],
	}

	result == {"module.networking.azurerm_network_security_group.web allows inbound access from any source"}
}

test_linux_virtual_machine_password_authentication_is_allowed if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.compute.azurerm_linux_virtual_machine.app_vm",
						"type": "azurerm_linux_virtual_machine",
						"values": {"disable_password_authentication": true},
					}],
				}],
			},
		},
	}

	count(result) == 0
}

test_compliant_sample_has_no_policy_denials if {
	result := security.deny with input as {
		"resource_changes": [
			{
				"address": "module.application_gateway.azurerm_public_ip.app_gw_pip",
				"type": "azurerm_public_ip",
				"change": {"after": {"sku": "Standard"}},
			},
			{
				"address": "module.networking.azurerm_network_security_group.app_gateway",
				"type": "azurerm_network_security_group",
				"change": {
					"after": {
						"security_rule": [{
							"access": "Allow",
							"direction": "Inbound",
							"protocol": "Tcp",
							"source_address_prefix": "Internet",
							"destination_port_range": "443",
						}],
					},
				},
			},
		],
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [
						{
							"address": "module.compute.azurerm_linux_virtual_machine_scale_set.web",
							"type": "azurerm_linux_virtual_machine_scale_set",
							"values": {"disable_password_authentication": true},
						},
						{
							"address": "module.monitoring.azurerm_log_analytics_workspace.main",
							"type": "azurerm_log_analytics_workspace",
							"values": {
								"internet_query_access_type": "Disabled",
								"retention_in_days": 90,
							},
						},
						{
							"address": "module.application_gateway.azurerm_application_gateway.main",
							"type": "azurerm_application_gateway",
							"values": {"http_listener": [{"protocol": "Https"}]},
						},
						{
							"address": "module.networking.azurerm_subnet.subnets[\"web_subnet\"]",
							"type": "azurerm_subnet",
							"values": {"default_outbound_access_enabled": false},
						},
						{
							"address": "module.networking.azurerm_subnet.subnets[\"app_gateway\"]",
							"type": "azurerm_subnet",
							"values": {"default_outbound_access_enabled": null},
						},
					],
				}],
			},
		},
	}

	count(result) == 0
}
