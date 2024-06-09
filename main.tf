provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = vpc-0cdce67bc93ef0672
  cidr_block        = "172.31.32.0/20"
  availability_zone = "ap-south-1"
}

resource "aws_security_group" "sg" {
  vpc_id = vpc-0cdce67bc93ef0672

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_ecs_cluster" "cluster" {
  name = "pearlthoughts"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "hello-world-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1"
  memory                   = "3"

  container_definitions = jsonencode([
    {
      name      = "hello-world-container"
      image     = "docker.io/salmanp7/hello-world-app:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = "hello-world-service"
  cluster         = "arn:aws:ecs:ap-south-1:533267382038:cluster/pearlthoughts"
  task_definition = "arn:aws:ecs:ap-south-1:533267382038:task-definition/pearlthoughts:1"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = subnet-08cc72eb216a15189
    security_groups  = sg-09e31ef2770a96f3b
    assign_public_ip = true
  }
}

