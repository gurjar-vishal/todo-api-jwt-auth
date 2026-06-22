terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC (use default) 
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ─── ECR 
resource "aws_ecr_repository" "todo_api" {
  name                 = "todo-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ─── CloudWatch Log Group 
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/todo-api"
  retention_in_days = 7
}

# ─── Security Groups 

# ALB: accepts HTTP from the internet
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS tasks: only accept traffic from ALB on port 3000
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS: only accept traffic from ECS tasks on port 5432
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL from ECS tasks only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ─── ECS Cluster 
resource "aws_ecs_cluster" "todo_cluster" {
  name = "todo-cluster"
}

# ─── IAM Role for ECS Task Execution 
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# ─── ECS Task Definition 
resource "aws_ecs_task_definition" "todo_api" {
  family                   = "todo-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "todo-api"
      image     = "${aws_ecr_repository.todo_api.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "DB_URL"
          value = var.db_url
        },
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        },
        {
          name  = "BASE_URL"
          value = "http://${aws_lb.todo_alb.dns_name}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ─── Application Load Balancer 
resource "aws_lb" "todo_alb" {
  name               = "todo-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "todo_tg" {
  name        = "todo-api-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.todo_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.todo_tg.arn
  }
}

# ─── ECS Service 
resource "aws_ecs_service" "todo_service" {
  name            = "todo-api-service"
  cluster         = aws_ecs_cluster.todo_cluster.id
  task_definition = aws_ecs_task_definition.todo_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.todo_tg.arn
    container_name   = "todo-api"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}
