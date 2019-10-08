########### aws details #########################

variable "tags" {
  type    = "map"
  default = {}
}

variable "aws_region" {
  type    = string
}

variable "aws_profile" {
  type    = string
}

variable "aws_creds_file" {
  type    = string
}

variable "key_name" {
  type    = string
}

variable "aws_azs" {
  type    = list
  default = ["eu-west-2a","eu-west-2b"]
}

variable "sles_image_name" {
  type    = string
  default = "suse-sles-12-sp3-byos-v20190623-hvm-ssd-x86_64"
}

variable "server_image_name" {
  type    = string
  default = "RHEL-7.6_HVM_GA-20190128-x86_64-0-Hourly2-GP2"
}

variable "sles_image_owner" {
  type    = string
  default = "013907871322"
}

variable "server_image_owner" {
  type    = string
  default = "309956199498"
}

variable "sles_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "chef_automate_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "chef_automate_root_disk_size" {
  default = 40
}

variable "chef_automate_count" {
  default = 1
}

variable "chef_supermarket_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "chef_supermarket_root_disk_size" {
  default = 40
}

variable "chef_supermarket_count" {
  default = 1
}

variable "chef_server_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "chef_server_root_disk_size" {
  default = 40
}

variable "chef_server_count" {
  default = 1
}


variable "chef_backend_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "chef_backend_root_disk_size" {
  default = 40
}

########### connection details ##################
variable "ssh_user_name" {
  type    = string
}

variable "ssh_user_pass" {
  type    = string
}

variable "create_ssh_user" {
  default = false
}

variable "ssh_user_public_key" {
  type    = string
  default = ""
}

variable "ssh_user_private_key" {
  type    = string
  default = ""
}

variable "timeout" {
  type    = string
  default = "5m"
}

########## chef supermarket config ###################

variable "chef_supermarket_hostname" {
  type    = string
}

########## chef server config ###################
variable "chef_server_hostname" {
  type    = string
}

variable "chef_server_users" {
  type    = map(object({ serveradmin=bool, first_name=string, last_name=string, email=string, password=string }))
  default = {}
}

variable "chef_server_orgs" {
  type    = map(object({ admins=list(string), org_full_name=string }))
  default = {}
}

variable "force_frontend_chef_run" {
  type    = string
  default = "default"
}

variable "chef_frontend_config" {
  type    = string
  default = ""
}

########### cluster backend secrets #####################

variable "postgresql_superuser_password" {
  type = string
}

variable "postgresql_replication_password" {
  type = string
}

variable "etcd_initial_cluster_token" {
  type = string
}

variable "elasticsearch_cluster_name" {
  type = string
}

########### chef automate config ################

variable "data_collector_token" {
  type    = string
  default = ""
}

variable "chef_automate_admin_password" {
  type    = string
  default = ""
}

variable "chef_automate_license" {
  type    = string
  default = ""
}

variable "chef_automate_hostname" {
  type    = string
}

########### dns settings ########################

variable "dnsimple_oauth_token" {
  type = string
}

variable "dnsimple_account" {
  type = string
}

variable "dnsimple_domain_name" {
  type = string
}

variable "issuer_url" {
  type    = string
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
