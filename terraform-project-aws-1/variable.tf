variable "subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
  type    = list(string)
}

variable "availability_zones" {
  description = "AZs in this region to use"
  default     = ["us-east-1a", "us-east-1b"]
  type        = list(string)
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_cidr" {
  default = "0.0.0.0/0"
}

variable "http_ingress_from_port" {
  default = 80
}

variable "http_ingress_to_port" {
  default = 80
}


variable "ssh_ingress_from_port" {
  default = 22
}

variable "ssh_ingress_to_port" {
  default = 22
}

variable "http_ingress_protocol" {
  default = "tcp"
}
 
variable "ssh_ingress_protocol" {
  default = "tcp"
}

variable "public_to_port" {
  default = 0
}

variable "public_from_port" {
  default = 0
}

variable "public_protocol" {
  default = "-1"
}

variable "ni_private_ips" {
  default = ["10.0.1.50", "10.0.1.51"]
  type = list(string)
}


 
