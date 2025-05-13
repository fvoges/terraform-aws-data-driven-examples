# retrieve vpc data from the data source
data "aws_vpc" "example" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# We need the supported architectures for the instance type
# to filter the AMI by architecture
data "aws_ec2_instance_type" "main" {
  instance_type = var.instance_type
}

# Search for the latest Ubuntu AMI
# with the specified architecture, virtualization type
# and the owneed by Canonical (099720109477)
# The AMI name pattern is based on the Ubuntu AMI naming convention
# and the architecture is based on the instance type
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-*-24.04-*-server-*"]
  }

  #filter by cpu architecture
  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.main.supported_architectures
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

