package policy_test

import data.terraform.security as security

test_public_ip_not_standard_deny if {
	result := security.deny with input as {
		"resource_changes": [{
			"address": "azurerm_public_ip.test",
			"type": "azurerm_public_ip",
			"change": {
				"after": {
					"sku": "Basic",
				},
			},
		}],
	}

	result == {"azurerm_public_ip.test uses a non-Standard SKU"}
}

test_inbound_ssh_deny if {
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

test_inbound_allow_all_deny if {
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

#Írj egy deny policy-t, amely jelez, ha egy azurerm_linux_virtual_machine_scale_set esetén a password authentication nincs letiltva.
test_pw_auth_not_blocked if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "azurerm_linux_virtual_machine_scale_set.test",
						"type": "azurerm_linux_virtual_machine_scale_set",
						"values": {
							"disable_password_authentication": false,
						},
					}],
				}],
			},
		},
	}

	result == {
		"azurerm_linux_virtual_machine_scale_set.test allows password authentication, which is prohibited.",
	}
}

test_lg_wp_internet_query_enabled if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "azurerm_log_analytics_workspace.test",
						"type": "azurerm_log_analytics_workspace",
						"values": {
							"internet_query_access_type": "Enabled",
						},
					}],
				}],
			},
		},
	}
	result == {"azurerm_log_analytics_workspace.test resource has internet_query_access_type Enabled"}
}

test_lg_wp_retention_days if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "azurerm_log_analytics_workspace.test",
						"type": "azurerm_log_analytics_workspace",
						"values": {
							"retention_in_days": 30,
						},
					}],
				}],
			},
		},
	}
	result == {"azurerm_log_analytics_workspace.test Log Analytics Workspace has a retention in days limit below 31"}
}

test_app_gateway_http_listener_deny if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.application_gateway.azurerm_application_gateway.network",
						"type": "azurerm_application_gateway",
						"values": {
							"http_listener": [{
								"protocol": "Http",
							}],
						},
					}],
				}],
			},
		},
	}

	result == {"module.application_gateway.azurerm_application_gateway.network listener does not use HTTPS"}
}

test_subnet_default_outbound_access_deny if {
	result := security.deny with input as {
		"planned_values": {
			"root_module": {
				"child_modules": [{
					"resources": [{
						"address": "module.networking.azurerm_subnet.subnets[\"web_subnet\"]",
						"type": "azurerm_subnet",
						"values": {
							"default_outbound_access_enabled": true,
						},
					}],
				}],
			},
		},
	}

	result == {"module.networking.azurerm_subnet.subnets[\"web_subnet\"] subnet has default outbound access enabled set to true"}
}

test_ssh_wildcard_protocol_ranges_and_cidr_deny if {
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

test_any_source_in_prefix_list_deny if {
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

test_compliant_sample_has_no_deny if {
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
							"address": "module.networking.azurerm_subnet.web",
							"type": "azurerm_subnet",
							"values": {"default_outbound_access_enabled": false},
						},
					],
				}],
			},
		},
	}

	count(result) == 0
}
