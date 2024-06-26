provider "aws" {
  region = "ap-south-1" // specify your desired AWS region
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "ecr-pull-policy"
  description = "IAM policy for pulling images from ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ecr:*",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_ecr_repository" "my_ecr_repository" {
  name = "node_app"
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-family"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions    = <<DEFINITION
[
  {
    "name": "my-container",
    "image": "${aws_ecr_repository.my_ecr_repository.repository_url}:latest",
    "cpu": 256,
    "memory": 512,
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}

resource "aws_alb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0bdf8cda61528bb8a"] // specify your ALB security group IDs
  subnets            = ["subnet-0b7b8bc8b8f0dc274", "subnet-0c373508a2c891fe2"] // specify your ALB subnet IDs

}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.my_target_group.arn
  }
}

resource "aws_alb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0ffc6bc04084e0119" // specify your VPC ID
  target_type       = "ip"

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets            = ["subnet-0b7b8bc8b8f0dc274", "subnet-0c373508a2c891fe2"] // specify your ALB subnet IDs
    security_groups  = ["sg-0bdf8cda61528bb8a"]     // specify your ECS security group IDs
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 3000
  }

  launch_type = "FARGATE"
  platform_version = "LATEST"
}