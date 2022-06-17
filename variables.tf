variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_az" {
  default = "eu-central-1a"
}

variable "aws_az1" {
  default = "eu-central-1b"
}

variable "subnet" {
  description = "Your AWS subnet"
  default     = ""
}


variable "key_name" {
  description = "Your AWS keyname"
  default = ""
  type    = string
}

variable "sec_group" {
  description = "Your AWS security group"
  default = ""
  type    = string
}
