locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  instance_hostname = "terraform-jenkins"
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


	provisioner "remote-exec" {
  			inline = ["sudo hostnamectl set-hostname ${instance_hostname}"]
	}

	tags = {
		Name = locals.instance_hostname
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
