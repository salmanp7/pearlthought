provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "pearlthoughts-vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "pearl" {
  vpc_id            = aws_vpc.pearlthoughts-vpc.id
  cidr_block        = "172.31.32.0/20"
  availability_zone = "ap-south-1a"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pearlthoughts-vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.pearlthoughts-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pearl.id
  route_table_id = aws_route_table.rt.id
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

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "pearlthoughts-clusters" {
  name = "pearlthoughts-clusters"
}

resource "aws_ecs_task_definition" "hello-world-task" {
  family                   = "hello-world-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

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
