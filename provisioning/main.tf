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
  depends_on = [ aws_s3_bucket.simple_web_app_backend_state ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_backend_encryption" {
  bucket = aws_s3_bucket.simple_web_app_backend_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  depends_on = [ aws_s3_bucket.simple_web_app_backend_state ]
}

# Locking - DynamoDB
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
  name = "simple-web-app"
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
    cidr_blocks = ["124.120.201.166/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["124.120.201.166/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create new sg for vault to allow only jenkins sg to access
resource "aws_security_group" "vault_sg" {
  name   = "vault_sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["124.120.201.166/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0" ]
  }
}

# Create keypair for vault
resource "aws_key_pair" "vault_key" {
  key_name   = "vault-key"
  public_key = file("~/Downloads/vault-key.pub")
}

# Create ec2 instance for vault
resource "aws_instance" "vault" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = "vault-key"
  security_groups = ["${aws_security_group.vault_sg.name}"]
  tags = {
    Name = "vault"
  }
  # userdata for install vault
  user_data = file("vault_userdata.sh")

  provisioner "file" {
    source      = "vault"
    destination = "/home/ubuntu/vault"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/Downloads/vault-key")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source    = "~/Downloads/vault-key"
    destination = "/home/ubuntu/vault-key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/Downloads/vault-key")
      host        = self.public_ip
    }
  }
  depends_on = [ aws_key_pair.vault_key, aws_security_group.vault_sg ]
}

# create keypair for jenkins
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = file("~/Downloads/jenkins-key.pub")
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
  user_data = file("jenkins_userdata.sh")
  depends_on = [ aws_key_pair.jenkins_key, aws_security_group.jenkins_sg ]
}