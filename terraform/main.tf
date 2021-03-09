locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  instance_hostname = "terraform-jenkins"
  private_key = "${path.module}/../secrets/id_rsa_ssh_terraform-jenkins"
}
  
variable "my_public_ip" {
  type = string
}
  
data "aws_ami" "myimage" {
  most_recent = true
  owners      = ["self"]

  name_regex = "^packer-example*"

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

}


resource "aws_instance" "instance" {
	ami = data.aws_ami.myimage.id
	instance_type = "t2.micro"
	vpc_security_group_ids = [aws_security_group.sg.id]

	user_data = <<-EOF
		#!/bin/bash
		cat /tmp/123 >> index.html
        echo "spawned by terraform" >> index.html
		nohup busybox httpd -f -p ${var.server_port} &
		EOF

  	connection {
    	type = "ssh"
    	user = "ubuntu"
    	private_key = file(local.private_key)
    	host = aws_instance.instance.public_ip
  	} 

	provisioner "remote-exec" {
  			inline = ["sudo hostnamectl set-hostname --static ${local.instance_hostname}"]
	}

	tags = {
		Name = local.instance_hostname
	}
}

resource "aws_security_group" "sg" {
	name = "terraform-jenkins-${local.timestamp}"
	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["${var.my_public_ip}/32"]
	}
}


variable "server_port" {
	description = "The port the server will use for HTTP requests"
	type = number
	default = 8080
}


output "public_ip" {
	value = aws_instance.instance.public_ip
	description = "The public IP address of the web server"
}


### The Ansible inventory file
resource "local_file" "hosts_cfg" {
  content = templatefile("${path.root}/templates/hosts.tpl",
    {
      servers = [aws_instance.instance.public_dns]
    }
  )
  filename = "${path.cwd}/inventories/hosts.cfg"
}