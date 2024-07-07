resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-kdash-example"
    engine = "mysql"
    allocated_storage = 10
    instance_class = var.instance_type
    db_name = "example_database"
    skip_final_snapshot = true
    username = var.db_username
    password = var.db_password
}
