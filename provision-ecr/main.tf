provider "aws" {
  region = "us-east-1"
}
# provision the ECR
resource "aws_ecr_repository" "simple_web_app" {
  name = "simple-web-app"
}