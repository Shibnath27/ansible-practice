variable "aws_region" {
  description = "AWS region for infrastructure"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "terra-key-ansible"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 10
}

variable "ssh_key_path" {
  description = "Path to the SSH private key on the Ansible control node"
  type        = string
  default     = "~/keys/terra-key-ansible"
}


variable "instances" {

  description = "Map of instance names to AMI IDs, SSH users, and OS family"
  
  type = map(object({
    ami       = string
    user      = string
    os_family = string
    instance_type = string
  }))

  # by deafult value to be put in the variable
  default = {
    "control-node-ubuntu" = {
      ami       = "ami-0d76b909de1a0595d" # Ubuntu Server 24.04 LTS
      user      = "ubuntu"
      os_family = "ubuntu"
      instance_type = "t3.micro"
    }
    "worker-ubuntu" = {
      ami       = "ami-0d76b909de1a0595d" # Ubuntu Server 24.04 LTS 
      user      = "ubuntu"
      os_family = "ubuntu"
      instance_type = "t3.micro"
    }
    "worker-redhat" = {
      ami       = "ami-04c7815cd1d6c8fa4" # RHEL 9 
      user      = "ec2-user"
      os_family = "redhat"
      instance_type = "t3.micro"
    }
    "worker-amazon" = {
      ami       = "ami-043ab4148b7bb33e9" # Amazon Linux 2023 — update for your region
      user      = "ec2-user"
      os_family = "amazon"
      instance_type = "t3.micro"
    }
  }
}
