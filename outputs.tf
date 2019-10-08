#output "supermarket_url" {
#  value = module.chef_supermarket.supermarket_url
#}
#
#output "automate_url" {
#  value = module.chef_automate.url
#}
#
#output "automate_token" {
#  value = module.chef_automate.token
#}

output "chef_server_url" {
  value = module.chef_backend_cluster.chef_server_org_url
}

output "frontendis_ip" {
  value = module.chef_server_nodes.public_ip
}

output "bootstrap_node_ip" {
  value = module.bootstrap_node.public_ip
}

output "backend_nodes_ip" {
  value = module.backend_nodes.public_ip
}
