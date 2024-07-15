variable "name" {
    description = "The name to use for all the resources created by this module"
    type        = string
}

variable "image" {
    description = "Docker image to run"
    type        = string
}

variable "container_port" {
    description = "Port to expose from the docker image"
    type        = number
}

variable "replicas" {
    description = "Number of docker containers to run"
    type        = number
}

variable "environment_variables" {
    description = "Environment variables to pass to the container"
    type        = map(string)
    default     = {}
}
