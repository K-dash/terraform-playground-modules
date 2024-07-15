terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

resource "aws_db_instance" "example" {
    identifier_prefix = "terraform-kdash-example"
    allocated_storage = 10
    instance_class = var.instance_type
    skip_final_snapshot = true
    
    # バックアップを有効化
    backup_retention_period = var.backup_retention_period
    
    # 設定されている時はこのデータベースはレプリカ
    replicate_source_db = var.replication_source_db

    # replication_source_db が指定されていない場合のみこれらのパラメータを設定する
    engine =  var.replication_source_db == null ? "mysql" : null
    db_name = var.replication_source_db == null ? var.db_name : null
    username = var.replication_source_db == null ? var.db_username : null
    password = var.replication_source_db == null ? var.db_password : null
}
