# ローカル変数
locals {
    http_port = 80
    any_port = 0
    any_protocol = "-1"
    tcp_protocol = "tcp"
    all_ips = ["0.0.0.0/0"]
}


# DBのstateファイルから情報を取得する
data "terraform_remote_state" "db" {
    backend = "s3"
    config = {
        bucket = var.db_remote_state_bucket
        key = var.db_remote_state_key
        region = "us-east-2"
    }
}

# 起動設定
resource "aws_launch_configuration" "example" {
    image_id = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.instance.id]
    
    # ユーザーデータをテンプレートとしてレンダリング
    user_data = templatefile("${path.module}/user-data.sh", {
        server_port = var.server_port
        db_address = data.terraform_remote_state.db.outputs.address
        db_port = data.terraform_remote_state.db.outputs.port
        server_text = var.server_text
    })

    # Autoscaling Groupの起動設定の場合は必須
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_security_group" "instance" {
    name = "${var.cluster_name}-instance"
    
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_autoscaling_group" "example" {
    # 起動設定の名前に明示的に依存させることで、起動設定が置き換えられたらASGも更新させる
    name = "${var.cluster_name}-${aws_launch_configuration.example.name}"

    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnets.default.ids
    
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"
    
    min_size = var.min_size
    max_size = var.max_size
    
    # ASGデプロイが完了すると判断する前に、最低でも指定した数のインスタンスがヘルスチェックをパスするのを待つ
    min_elb_capacity = var.min_size

    # ASGを置き換える時、置き換え先を先に作成してから元のASGを削除
    lifecycle {
        create_before_destroy = true
    }

    tag {
        key = "Name"
        value = var.cluster_name
        propagate_at_launch = true
    }
    
    dynamic "tag" {
        for_each = {
            for key, value in var.custom_tags:
            key => upper(value)
            if key != "Name"
        }
        content {
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }
}

# data source
data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}


# ALB
resource "aws_lb" "example" {
    name = var.cluster_name
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

# ALB Listener
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port = local.http_port
    protocol = "HTTP"
    
    # デフォルトはシンプルな404ページを返す
    default_action {
        type = "fixed-response"
        
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

# ALB Target Group
resource "aws_lb_target_group" "asg" {
    name = var.cluster_name
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

# ALB Security Group
resource "aws_security_group" "alb" {
    name = "${var.cluster_name}-alb"
}

# ALB Security Group Rule for inbound
resource "aws_security_group_rule" "allow_http_inbound" {
    # permit internal traffic
    type = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}

# ALB Security Group Rule for outbound
resource "aws_security_group_rule" "allow_http_outbound" {
    # permit external traffic
    type = "egress"
    security_group_id = aws_security_group.alb.id
    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

# Autoscaling Schedule
resource "aws_autoscaling_schedule" "schedule_out_during_business_hours" {
    count = var.enable_auto_scaling ? 1 : 0

    scheduled_action_name = "scale_out_during_business_hours"
    min_size = 2
    max_size = 10
    desired_capacity = 10
    recurrence = "0 9 * * *"
    autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = var.enable_auto_scaling ? 1 : 0

    scheduled_action_name = "scale_in_at_night"
    min_size = 2
    max_size = 10
    desired_capacity = 2
    recurrence = "0 17 * * *"
    autoscaling_group_name = aws.autoscaling_group.example.name
}
