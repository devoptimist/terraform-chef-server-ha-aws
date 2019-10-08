terraform {
  required_version = "> 0.12.0"
}

provider "aws" {
  shared_credentials_file = "${var.aws_creds_file}"
  profile                 = "${var.aws_profile}"
  region                  = "${var.aws_region}"
}

resource "random_id" "hash" {
  byte_length = 4
}

locals {
  common_name                = "${lookup(var.tags, "prefix", "changeme")}-${random_id.hash.hex}"
  ssh_user_private_key       = var.ssh_user_private_key
  bootstrap                  = templatefile("${path.module}/templates/bootstrap.sh", {
    create_ssh_user          = var.create_ssh_user,
    ssh_user_name            = var.ssh_user_name,
    ssh_user_pass            = var.ssh_user_pass,
    ssh_user_public_key      = file(var.ssh_user_public_key)
  })
}

module "vpc" {
  source                  = "terraform-aws-modules/vpc/aws"
  version                 = "2.5.0"
  name                    = "${local.common_name}-chef-vpc"
  cidr                    = "10.0.0.0/16"
  azs                     = var.aws_azs
  public_subnets          = ["10.0.1.0/24"]
  map_public_ip_on_launch = true
  tags                    = var.tags
}

module "sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "3.0.1"
  name                = "${local.common_name}-security-group"
  description         = "security group to enable ssh"
  vpc_id              = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 2379
      to_port     = 2380
      protocol    = "tcp"
      description = "etcd"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "postgresql"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 7331
      to_port     = 7331
      protocol    = "tcp"
      description = "leaderl"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 9200
      to_port     = 9400
      protocol    = "tcp"
      description = "leaderl"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
  ingress_rules       = ["ssh-tcp","https-443-tcp","http-80-tcp"]
  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
}

data "aws_ami" "sles_image" {
  most_recent = true
  owners      = [var.sles_image_owner]

  filter {
    name      = "name"
    values    = [var.sles_image_name]
  }
}

data "aws_ami" "server_image" {
  most_recent = true
  owners      = [var.server_image_owner]

  filter {
    name      = "name"
    values    = [var.server_image_name]
  }
}

module "chef_supermarket_nodes" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "2.0.0"
  name                        = "${local.common_name}-chef-supermarket"
  instance_count              = var.chef_supermarket_count
  ami                         = data.aws_ami.sles_image.id
  instance_type               = var.chef_supermarket_instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = ["${module.sg.this_security_group_id}"]
  subnet_id                   = module.vpc.public_subnets[0]
  root_block_device = [{
    volume_type = "gp2"
    volume_size = var.chef_supermarket_root_disk_size
  }]
  tags                        = var.tags
  user_data                   = local.bootstrap
}

module "chef_automate_nodes" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "2.0.0"
  name                        = "${local.common_name}-chef-automate"
  instance_count              = var.chef_automate_count
  ami                         = data.aws_ami.sles_image.id
  instance_type               = var.chef_automate_instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = ["${module.sg.this_security_group_id}"]
  subnet_id                   = module.vpc.public_subnets[0]
  root_block_device = [{
    volume_type = "gp2"
    volume_size = var.chef_automate_root_disk_size
  }]
  tags                        = var.tags
  user_data                   = local.bootstrap
}

module "chef_server_nodes" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "2.0.0"
  name                        = "${local.common_name}-chef-server"
  instance_count              = var.chef_server_count
  ami                         = data.aws_ami.sles_image.id
  instance_type               = var.chef_server_instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = ["${module.sg.this_security_group_id}"]
  subnet_id                   = module.vpc.public_subnets[0]
  root_block_device = [{
    volume_type = "gp2"
    volume_size = var.chef_server_root_disk_size
  }]
  tags                        = var.tags
  user_data                   = local.bootstrap
}

module "bootstrap_node" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "2.0.0"
  name                        = "${local.common_name}-chef-ha-cluster-bootstrap-backend"
  instance_count              = 1
  ami                         = data.aws_ami.sles_image.id
  instance_type               = var.chef_backend_instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = ["${module.sg.this_security_group_id}"]
 subnet_id                   = module.vpc.public_subnets[0]
  root_block_device = [{
    volume_type = "gp2"
    volume_size = var.chef_backend_root_disk_size
  }]
  tags                        = var.tags
  user_data                   = local.bootstrap
}

module "backend_nodes" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "2.0.0"
  name                        = "${local.common_name}-chef-ha-cluster-backend"
  instance_count              = 2
  ami                         = data.aws_ami.sles_image.id
  instance_type               = var.chef_backend_instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = ["${module.sg.this_security_group_id}"]
  subnet_id                   = module.vpc.public_subnets[0]
  root_block_device = [{
    volume_type = "gp2"
    volume_size = var.chef_backend_root_disk_size
  }]
  tags                        = var.tags
  user_data                   = local.bootstrap
}

locals {
  chef_server_records = { for ip in module.chef_server_nodes.public_ip : "${var.chef_server_hostname}-${index(module.chef_server_nodes.public_ip, ip)}" => ip }
  chef_supermarket_records = { for ip in module.chef_supermarket_nodes.public_ip : "${var.chef_supermarket_hostname}-${index(module.chef_supermarket_nodes.public_ip, ip)}" => ip }
  chef_automate_records = { for ip in module.chef_automate_nodes.public_ip : "${var.chef_automate_hostname}-${index(module.chef_automate_nodes.public_ip, ip)}" => ip }
  addons = {
    "manage" = {
      "config" = "",
      "channel" = "stable",
      "version" = "2.5.16"
    }
  }
}

module "chef_server_dns_and_cert" {
  source         = "/home/steveb/workspace/terraform/modules/devoptimist/terraform-dnsimple-record-cert"
  records        = local.chef_server_records
  instance_count = var.chef_server_count
  contact        = lookup(var.tags, "contact") 
  domain_name    = var.dnsimple_domain_name
  issuer_url     = var.issuer_url
  oauth_token    = var.dnsimple_oauth_token
  account        = var.dnsimple_account
}

module "chef_automate_dns_and_cert" {
  source         = "/home/steveb/workspace/terraform/modules/devoptimist/terraform-dnsimple-record-cert"
  records        = local.chef_automate_records
  instance_count = var.chef_supermarket_count
  contact        = lookup(var.tags, "contact") 
  domain_name    = var.dnsimple_domain_name
  issuer_url     = var.issuer_url
  oauth_token    = var.dnsimple_oauth_token
  account        = var.dnsimple_account
}

module "chef_supermarket_dns_and_cert" {
  source         = "/home/steveb/workspace/terraform/modules/devoptimist/terraform-dnsimple-record-cert"
  records        = local.chef_supermarket_records
  instance_count = var.chef_supermarket_count
  contact        = lookup(var.tags, "contact") 
  domain_name    = var.dnsimple_domain_name
  issuer_url     = var.issuer_url
  oauth_token    = var.dnsimple_oauth_token
  account        = var.dnsimple_account
}

module "chef_backend_cluster" {
  source                          = "/home/steveb/workspace/terraform/modules/devoptimist/terraform-linux-chef-backend"
  bootstrap_node_ip               = module.bootstrap_node.public_ip[0]
  peers                           = module.bootstrap_node.private_ip[0]
  backend_ips                     = module.backend_nodes.public_ip
  frontend_ips                    = module.chef_server_nodes.public_ip
  frontend_node_count             = var.chef_server_count
  frontend_private_ips            = module.chef_server_nodes.private_ip
  ssh_user_name                   = var.ssh_user_name
  ssh_user_private_key            = local.ssh_user_private_key
#  frontend_fqdns                  = module.chef_server_dns_and_cert.certificate_domain
#  frontend_certs                  = module.chef_server_dns_and_cert.certificate_pem
#  frontend_cert_keys              = module.chef_server_dns_and_cert.private_key_pem
  frontend_users                  = var.chef_server_users
  frontend_orgs                   = var.chef_server_orgs
  frontend_addons                 = local.addons
# supermarket_url                 = module.chef_supermarket_dns_and_cert.certificate_domain
#  data_collector_url              = module.chef_automate.url
#  data_collector_token            = module.chef_automate.token
  postgresql_superuser_password   = var.postgresql_superuser_password
  postgresql_replication_password = var.postgresql_replication_password
  etcd_initial_cluster_token      = var.etcd_initial_cluster_token
  elasticsearch_cluster_name      = var.elasticsearch_cluster_name
  force_frontend_chef_run         = var.force_frontend_chef_run
  timeout                         = var.timeout
}

#module "chef_supermarket" {
#  source                = "/home/steveb/workspace/terraform/modules/devoptimist/terraform-linux-chef-supermarket"
#  ips                   = module.chef_supermarket_nodes.public_ip
#  instance_count        = var.chef_supermarket_count
#  ssh_user_name         = var.ssh_user_name
#  ssh_user_private_key  = local.ssh_user_private_key
#  fqdns                 = module.chef_supermarket_dns_and_cert.certificate_domain
#  certs                 = module.chef_supermarket_dns_and_cert.certificate_pem
#  cert_keys             = module.chef_supermarket_dns_and_cert.private_key_pem
#  chef_server_urls      = module.chef_backend_cluster.chef_frontend_base_url
#  chef_oauth2_app_ids   = module.chef_backend_cluster.supermarket_uid
#  chef_oauth2_secrets   = module.chef_backend_cluster.supermarket_secret
#  timeout               = var.timeout
#}
#
#module "chef_automate" {
#  source                = "/home/steveb/workspace/terraform/modules/devoptimist/terraform-linux-chef-automate"
#  ips                   = module.chef_automate_nodes.public_ip
#  instance_count        = var.chef_automate_count
#  ssh_user_name         = var.ssh_user_name
#  ssh_user_private_key  = local.ssh_user_private_key
#  fqdns                 = module.chef_automate_dns_and_cert.certificate_domain
#  certs                 = module.chef_automate_dns_and_cert.certificate_pem
#  cert_keys             = module.chef_automate_dns_and_cert.private_key_pem
#  chef_automate_license = var.chef_automate_license
#  data_collector_token  = var.data_collector_token
#  admin_password        = var.chef_automate_admin_password
#  timeout               = var.timeout
#}
