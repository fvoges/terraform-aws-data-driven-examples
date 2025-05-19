
# manage an ec2 instance with ebs volumes controlled by an input variable
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Create EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.ebs_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_size           = ebs_block_device.value.volume_size
      delete_on_termination = true
    }
  }
}

#manage the security group for the ec2 instance with no default rules
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Security group for example instance"
  vpc_id      = data.aws_vpc.example.id
}

#add rules to the security group managed by input variables using for_each
resource "aws_security_group_rule" "example" {
  for_each = var.security_group_rules

  description       = each.key
  type              = try(each.value.type, "ingress")
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = try(each.value.protocol, "tcp")
  cidr_blocks       = coalesce(each.value.cidr_blocks, var.ingress_ipv4_cidr_allow)
  ipv6_cidr_blocks  = coalesce(each.value.ipv6_cidr_blocks, var.ingress_ipv6_cidr_allow)
  security_group_id = aws_security_group.example.id
}
