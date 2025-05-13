# Terraform input variable and dynamic blocks example

## Code with variables

```hcl
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
```

## Effective code example when using a single member of a list


Input data

```hcl
ebs_volumes = [ {
    device_name = "/dev/sdf"
    volume_size = 30
  }]

```

Rendered code

```hcl
# manage an ec2 instance with ebs volumes controlled by an input variable
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 30
    delete_on_termination = true
  }
}
```

## Effective code example when using a multiple members of a list

Input data

```hcl
ebs_volumes = [ {
    device_name = "/dev/sdf"
    volume_size = 30
  },
  {
    device_name = "/dev/sdg"
    volume_size = 450
  }
  ]
```

Rendered code

```hcl
# manage an ec2 instance with ebs volumes controlled by an input variable
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 30
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = 450
    delete_on_termination = true
  }
}
```
