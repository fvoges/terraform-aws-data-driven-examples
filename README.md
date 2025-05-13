# Terraform data-driven examples

This repo contains example of how to dynamically generate resources using input data (variables).

The basic idea is to create code that can be customized by using only input variables. Reducing, or even eliminating, the need to make code changes for applying configuration changes.

## Multiple resources with `for_each`

### Managing security group rules with `for_each`

In this example, we use the `for_each` meta-argument to generate multiple resources based on the values of a variable.

```hcl
# Define the security group rules input variable
# The format is a map of objects
# where the key is the name of the security group rule
# and the value is a set of key/values that correspond
# to the security_group_rule resource parameters
#
# We also provide a de
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
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0::0/0"]
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

  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = coalesce(each.value.cidr_blocks, var.ingress_ipv4_cidr_allow)
  ipv6_cidr_blocks  = coalesce(each.value.ipv6_cidr_blocks, var.ingress_ipv6_cidr_allow)
  security_group_id = aws_security_group.example.id
}
```

In the code above we:

1. Define the input variable
   - A map of objects, where:
     - Each key are the names of the security group rules to create,
     - Each value is a set of key/values that correspond to the `security_group_rule` resource parameters to create.
2. Declare the `security_group_rule` resource
3. The first line inside the resource tells Terraform that we're going to create multiple resources using the contents of the `var.security_group_rules` input variable
4. The rest of the code use the list of key/values from each member of the map to provide the values for each resource parameter
5. Finally, we use `coalesce()` to provide default values for the `cidr_blocks` and `ipv6_cidr_blocks` parameters.
   - Coalesce will return the value of the first argument that is no an empty string, or `null`. If all the parameters are `null` or an empty string, it will return `null`.

## Dynamic blocks

In this example, we use [dynamic blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks), [the `for_each` meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each), and [input variables](https://developer.hashicorp.com/terraform/language/values/variables) to control the `ebs_block_device` block inside an `aws_instance` resource declaration.

When you want to be able to allow to customize blocks within a resource, Terraform provides the dynamic block feature. This allows you to use a `for_each` to generate the block, as the name implies, dynamically based on the variable's content.

See the example code below:

```hcl
# We define an input variable that accepts a list of objects
# We also define the object structure and provide a default value
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

At the top, we have the input variable definition. Then, we have a resource that uses that input variable.

Inside the `aws_instance` resource, the code with a dynamic block that works as follows:

1. The `dynamic` line tells terraform that we're going to create a list of `ebs_block_device` blocks.
2. The next line is where we say that we're going to use `var.ebs_volumes` as our data source.
3. Terraform will iterate over each member of the specified variable (`var.ebs_volumes`), and create a `ebs_block_device` block for each.
4. The following lines inside the `content` block describe the content of each of the `ebs_block_device` blocks generated. Here, Terraform will do variable interpolation, replacing the right have side values, with the values from each iteration of `var.ebs_volumes`.

The next section provide examples of the resulting code using different input values.

> **NOTE:**
>
> The code is rendered internally, when generating the list of resources and dependencies that terraform will manage. Terraform doesn't modify the source code when using dynamic blocks.

## Default values

If we use the default values as input:

```hcl
ebs_volumes = [{
  device_name = "/dev/sdf"
  volume_size = 30
}]

```

The code would be equivalent to writing this with hardcoded values:

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

## Using multiple list members in the input variable

If we use the following as input:

```hcl
ebs_volumes = [
  {
    device_name = "/dev/sdh"
    volume_size = 20
  },
  {
    device_name = "/dev/sdg"
    volume_size = 450
  }
]
```

Then, the code would be equivalent to writing this with hardcoded values:

```hcl
# manage an ec2 instance with ebs volumes controlled by an input variable
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_size           = 20
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = 450
    delete_on_termination = true
  }
}
```

Note that in this case, we end up with two `ebs_block_device` blocks, and the default values are not used.

## Additional information

- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [dynamic Blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
- [The `for_each` meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
- [coalesce Function](https://developer.hashicorp.com/terraform/language/functions/coalesce)
- [AWS EC2 instance - EBS block devices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#ebs-ephemeral-and-root-block-devices)
