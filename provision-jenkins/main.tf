provider "aws" {
  region = "us-east-1"
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

# # create keypair for jenkins
# resource "aws_key_pair" "jenkins_key" {
#   key_name   = "jenkins-key"
#   public_key = file("jenkins-key.pub")
# }

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
  user_data = <<-EOF
              #!/bin/bash
 
              curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
                /usr/share/keyrings/jenkins-keyring.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                /etc/apt/sources.list.d/jenkins.list > /dev/null

              sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

              wget -O- https://apt.releases.hashicorp.com/gpg | \
                gpg --dearmor | \
                sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
              https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
              sudo tee /etc/apt/sources.list.d/hashicorp.list

              echo \
                "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

              sudo apt-get update
              sudo apt-get install ca-certificates curl gnupg
              sudo install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              sudo chmod a+r /etc/apt/keyrings/docker.gpg

              sudo apt-get install openjdk-11-jdk -y
              sudo apt-get install jenkins -y
              sudo apt-get install openjdk-8-jdk -y
              sudo apt-get install docker.io -y
              sudo usermod -a -G docker jenkins
              sudo apt-get install unzip -y
              sudo apt-get install terraform -y

              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              rm -rf aws*

              sudo reboot
              EOF
}