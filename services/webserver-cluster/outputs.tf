output "alb_dns_name" {
    value = aws_lb.example.dns_name
    description = "The domain name of the load balancer"
}

output "asg_name" {
    value = aws_autoscaling_group.example.name
    description = "value of the Auto Scaling Group name"
}

output "alb_security_group_id" {
    value = aws_security_group.alb.id
    description = "The ID of the security group for the load balancer"
}
