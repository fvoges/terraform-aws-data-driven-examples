variable "aws_region" {
  type        = string
  description = "AWS region to deploy to"
  default     = null
}

variable "aws_profile" {
  type        = string
  description = "AWS profile to use"
  default     = null
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC to use"
  default     = "default"
}

variable "ssh_key_pair" {
  type        = string
  description = "Existing SSH key pair for bastion host"
}

variable "ingress_ipv4_cidr_allow" {
  type        = list(string)
  description = "List of IPv4 CIDR's to allow ingress to bastion EC2 instance security group"
}

variable "ingress_ipv6_cidr_allow" {
  type        = list(string)
  description = "List of IPv6 CIDR's to allow ingress to bastion EC2 instance security group"
}

############################################################################################################################################################
#
#

variable "instance_type" {
  type        = string
  description = "EC2 instance type tu use"
  default     = "t4g.nano"
}

variable "ebs_volumes" {
  type = list(object({
    device_name = string
    volume_size = number
  }))
  description = "List of EBS volumes to attach to the EC2 instance"
  default = [
    {
      device_name = "/dev/sdf"
      volume_size = 30
    }
  ]
}

variable "security_group_rules" {
  type = map(object({
    type             = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
  }))
  description = "Security group rules for the EC2 instance"
  # provide a default set of rules allowing SSH access from the bastion host
  default = {
    "ssh" = {
      type             = "ingress"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = null
      ipv6_cidr_blocks = null
    }
  }
}

