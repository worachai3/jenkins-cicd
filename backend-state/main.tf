provider "aws" {
  region = "us-east-1"
}

//S3 bucket
resource "aws_s3_bucket" "enterprise_backend_state" {
  bucket = "dev-applications-backend-state-worachai"
  
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "s3_backend_versioning" {
  bucket = aws_s3_bucket.enterprise_backend_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_backend_encryption" {
  bucket = aws_s3_bucket.enterprise_backend_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

//Locking - DynamoDB

resource "aws_dynamodb_table" "enterprise_backend_state_lock" {
  name           = "dev-applications-locks"
  billing_mode   = "PAY_PER_REQUEST"
  
	hash_key = "LockID"
	
  attribute {
    name = "LockID"
    type = "S"
  }
}