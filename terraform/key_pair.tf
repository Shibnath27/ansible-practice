resource "aws_key_pair" "ansible" {
  key_name   = var.key_name
  public_key = file("${path.module}/terra-key-ansible.pub")
}
