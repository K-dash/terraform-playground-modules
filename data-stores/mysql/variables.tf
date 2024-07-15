variable "db_username" {
    description = "The username for the database"
    type = string
    sensitive = true
    default = null
}

variable "db_password" {
    description = "The password for the database"
    type = string
    sensitive = true
    default = null
}

variable "db_name" {
    description = "The name of the database"
    type = string
    default = null
}

variable "instance_type" {
    description = "The type of RDS Instance"
    type = string
}

variable "backup_retention_period" {
    description = "Days to retain backups. Must be > 0 to enable replication."
    type = number
    default = null
}

variable "replication_source_db" {
    description = "If specified, replicate the RDS database at the given ARN."
    type = string
    default = null
}
