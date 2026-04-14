variable "aws_region" {
    description = "AWS region used for the lab"
    type = string
    default = "us-east-2"
}

variable "server_port" {
    description = "TCP port for the web server"
    type = number
    default = 8080
}