variable "access_key" {
  description = "AWS account access key"
}

variable "secret_key" {
  description = "AWS account secret key"
}

variable "region" {
  description = "The region to launch the factorio server"
}

variable "server_ami" {
  default = {
    # Ubuntu 18.04
    "ca-central-1"    = "ami-0f863d9d0b0bf6602"  # Montreal
    "ap-southeast-1"  = "ami-0ccaa193408259c82"  # Singapore
    "ap-south-1"      = "ami-04b17f6875b4d9c29"  # Mumbai
  }
}

variable "instance_type" {
  description = "Size of server on EC2"
}

variable "key_name" {
  description = "The ssh key for the factorio server"
}

variable "factorio_version" {
  description = "The version of factorio beta to install"
  default = "0.17.15"
}
