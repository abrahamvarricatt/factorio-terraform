provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"

  version = "~> 1.7"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("${var.key_name}.pub")}"
}

resource "aws_vpc" "factorio-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "factorio-server"
  }
}

resource "aws_internet_gateway" "factorio-ig" {
  vpc_id = "${aws_vpc.factorio-vpc.id}"

  tags {
    Name = "factorio-server"
  }
}

resource "aws_subnet" "public_subnet_factorio" {
  vpc_id                  = "${aws_vpc.factorio-vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "factorio-server"
  }
}

resource "aws_route_table" "public_factorio" {
  vpc_id = "${aws_vpc.factorio-vpc.id}"

  tags {
    Name = "factorio-server"
  }
}

resource "aws_route" "public_internet_gateway_factorio" {
  route_table_id         = "${aws_route_table.public_factorio.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.factorio-ig.id}"
}

resource "aws_route_table_association" "public_factorio" {
  subnet_id      = "${aws_subnet.public_subnet_factorio.id}"
  route_table_id = "${aws_route_table.public_factorio.id}"
}

resource "aws_security_group" "factorio-server" {
  name        = "factorio-host-security-group"
  description = "Allow SSH/game-connections to factorio host"
  vpc_id      = "${aws_vpc.factorio-vpc.id}"

  tags {
    Name = "factorio-server"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "factorio-server" {
  ami                         = "${lookup(var.server_ami, var.region)}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  monitoring                  = true
  vpc_security_group_ids      = ["${aws_security_group.factorio-server.id}"]
  subnet_id                   = "${aws_subnet.public_subnet_factorio.id}"
  associate_public_ip_address = true

  tags {
    Name = "factorio-server"
  }

  /* Copy our provisioning script */
  provisioner "file" {
    source      = "files/settings/setup.sh"
    destination = "/tmp/setup.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("factorio_key")}"
    }
  }

  /* Copy server settings file to remote */
  provisioner "file" {
    source      = "files/settings/server-settings.json"
    destination = "/tmp/server-settings.json"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("factorio_key")}"
    }
  }

  /* Copy latest save file to remote */
  provisioner "file" {
    source      = "files/saves/server-save.zip"
    destination = "/tmp/server-save.zip"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("factorio_key")}"
    }
  }

  /* Copy server binaries to remote */
  provisioner "file" {
    source      = "files/server/factorio_headless_x64_0.16.51.tar.xz"
    destination = "/tmp/factorio_headless_x64_0.16.51.tar.xz"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("factorio_key")}"
    }
  }

  /* Install the game */
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("factorio_key")}"
    }

    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",

    ]
  }

  /* Download saves to local before server termination */
  # provisioner "local-exec" {
  #   when    = "destroy"
  #   command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.key_name} -r ubuntu@${aws_instance.factorio-server.public_ip}:/opt/factorio/saves/. files/saves"
  # }

}

output "public_ip" {
  value = "${aws_instance.factorio-server.public_ip}"
}
