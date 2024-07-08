variable "user_name" {
    description = "The name of the user"
    type = string
}

variable "give_neo_cloudwatch_full_access" {
    description = "If true, neo has full access to CloudWatch"
    type = bool
}
