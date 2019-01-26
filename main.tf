provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("${var.key_name}.pub")}"
}

resource "aws_security_group" "factorio-server" {
  name        = "factorio-host-security-group"
  description = "Allow SSH/game-connections to factorio host"

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
  ami                     = "${lookup(var.server_ami, var.region)}"
  instance_type           = "${var.instance_type}"
  key_name                = "${var.key_name}"
  vpc_security_group_ids  = ["${aws_security_group.factorio-server.id}"]
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
  provisioner "local-exec" {
    when    = "destroy"
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.key_name} -r ubuntu@${aws_instance.factorio-server.public_ip}:/opt/factorio/saves/. files/saves"
  }

}

output "public_ip" {
  value = "${aws_instance.factorio-server.public_ip}"
}
