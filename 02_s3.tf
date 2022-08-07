// BUCKET SETUP
resource "aws_s3_bucket" "b" {
  bucket = local.domain_name
  tags = {
    Environment = var.env_name
  }
}

// S3 BUCKET PRIVACY SETTINGS
resource "aws_s3_bucket_acl" "wwwacl" {
  bucket = local.domain_name
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "allow_access_to_all_files" {
  bucket = aws_s3_bucket.b.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "${aws_s3_bucket.b.arn}",
                "${aws_s3_bucket.b.arn}/*"
            ]
        }
    ]
}
EOF
}

// STATIC SITE HOSTING WITH S3
// Meets Criteria:
// Amazon CloudFront should be configured to distribute 
// the content from the S3 static site.
resource "aws_s3_bucket_website_configuration" "www" {
  bucket = local.domain_name

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
