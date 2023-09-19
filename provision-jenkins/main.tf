provider "aws" {
  region = "us-east-1"
}
# Create S3 bucket for backend state
resource "aws_s3_bucket" "simple_web_app_backend_state" {
  bucket = "simple-web-app-backend-state-worachai"
  
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "s3_backend_versioning" {
  bucket = aws_s3_bucket.simple_web_app_backend_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_backend_encryption" {
  bucket = aws_s3_bucket.simple_web_app_backend_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

//Locking - DynamoDB
resource "aws_dynamodb_table" "simple_web_app_backend_state_lock" {
  name           = "simple-web-app-locks"
  billing_mode   = "PAY_PER_REQUEST"
  
	hash_key = "LockID"
	
  attribute {
    name = "LockID"
    type = "S"
  }
}

# Create ECR repository
resource "aws_ecr_repository" "simple_web_app_ecr" {
  name = "simple-web-app-ecr"
}

# create default vpc
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# create new sg for jenkins
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["119.76.33.162/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["119.76.33.162/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create keypair for jenkins
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = file("jenkins-key.pub")
}

# create ec2 instance for jenkins
resource "aws_instance" "jenkins" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.small"
  key_name      = "jenkins-key"
  security_groups = ["${aws_security_group.jenkins_sg.name}"]
  tags = {
    Name = "jenkins"
  }
  # userdata for install jenkins
  user_data = file("userdata.sh")
  depends_on = [ aws_key_pair.jenkins_key, aws_security_group.jenkins_sg ]
}
