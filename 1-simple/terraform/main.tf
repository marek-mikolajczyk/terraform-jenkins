provider "aws" {
  region = "us-east-1"
}

locals {
  timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
  instance_hostname = "terraform-jenkins"
  private_key = "${path.module}/../secrets/id_rsa_ssh_terraform-jenkins"
}
  

variable "my_public_ip" {
  type = string
}
variable "server_port" {
	description = "The port the server will use for HTTP requests"
	type = number
	default = 8080
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


data "aws_s3_bucket" "s3-tf-state" {
  bucket = "terraform-state-12345abcde"
}

data "aws_s3_bucket" "s3-rsa" {
  bucket = "private-keys-12345abcde"
}

data "aws_s3_bucket" "s3-inventories" {
  bucket = "inventories-12345abcde"
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
    	user = "automation"
    	private_key = file(local.private_key)
    	host = aws_instance.instance.public_ip
		timeout = "1m"
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

### The Ansible inventory file

/*resource "local_file" "hosts_cfg" {
  content = templatefile("${path.root}/templates/hosts.tpl",
    {
      servers = [aws_instance.instance.public_dns]
    }
  )
  filename = "${path.cwd}/inventories/hosts.cfg"
}
*/

resource "aws_s3_bucket" "s3inventory" {
	bucket = "ansible-inventory-12345abcde"
  	acl    = "private"

  	versioning {
    	enabled = true
  	}
}

resource "aws_s3_bucket_object" "hosts" {
	bucket = aws_s3_bucket.s3-inventories.id
	key = "hosts.cfg"
  	content = templatefile(
			"${path.cwd}/templates/hosts.tpl",
    		{
      			servers = [aws_instance.instance.public_dns]
    		}
  		)

}


output "public_ip" {
	value = aws_instance.instance.public_ip
	description = "The public IP address of the web server"
}



