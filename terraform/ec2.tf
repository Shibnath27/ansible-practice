resource "aws_instance" "my_instance" {
  for_each = var.instances

  ami             = each.value.ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.ansible.key_name
  security_groups = [aws_security_group.ansible_lab.name]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name      = each.key
    OSFamily  = each.value.os_family
    ManagedBy = "terraform"
    Project   = "ansible-training"
  }

  depends_on = [aws_security_group.ansible_lab, aws_key_pair.ansible]
}
