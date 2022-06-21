provider "alicloud" {
  region = "cn-beijing"
}

resource "alicloud_ecs_key_pair" "publickey" {
  key_pair_name = var.key_name
  public_key    = var.public_key
}

resource "alicloud_security_group" "group" {
  name        = "tf_test_foo"
  description = "foo"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/80"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_vpc" "vpc" {
  vpc_name       = "first_vpc"
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/24"
  zone_id           = "cn-beijing-h"
  vswitch_name      = "first_vswitch"
}

# Create a new ECS instance for VPC
resource "alicloud_instance" "instance" {
  # cn-beijing
  availability_zone = "cn-beijing-h"
  security_groups   = alicloud_security_group.group.*.id
  key_name = alicloud_ecs_key_pair.publickey.key_pair_name

  # series III
  instance_type              = "ecs.t5-lc2m1.nano"
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "test_foo_system_disk_name"
  system_disk_description    = "test_foo_system_disk_description"
  image_id                   = "centos_8_4_x64_20G_alibase_20210824.vhd"
  instance_name              = "test_foo"
  vswitch_id                 = alicloud_vswitch.vswitch.id
  internet_max_bandwidth_out = 1
}

resource "ansible_host" "web" {
  inventory_hostname = alicloud_instance.instance.public_ip
  groups             = ["web"]
  vars = {
    port         = 80
    ansible_user = "root"
  }
}
