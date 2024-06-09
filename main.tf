provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "pearlthoughts-vpc" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_subnet" "pearl" {
  vpc_id            = aws_vpc.pearlthoughts-vpc.id
  cidr_block        = "172.31.32.0/20"
  availability_zone = "ap-south-1a"
}

resource "aws_security_group" "pearl" {
  vpc_id = aws_vpc.pearlthoughts-vpc.id

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

resource "aws_ecs_cluster" "pearlthoughts-clusters" {
  name = "pearlthoughts-clusters"
}

resource "aws_ecs_task_definition" "hello-world-task" {
  family                   = "hello-world-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

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
  cluster         = aws_ecs_cluster.pearlthoughts-clusters.id
  task_definition = aws_ecs_task_definition.hello-world-task.arn 
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.pearl.id]
    security_groups  = [aws_security_group.pearl.id]
    assign_public_ip = true
  }
}
