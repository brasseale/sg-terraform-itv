resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "cf_cp_access_policy" {
  name = "cf_cp_access_policy"
  role = aws_iam_role.iam_for_lambda.id

  //Terraform's "jsonencode" function converts a
  //Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:CreateInvalidation",
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult",
          //  "logs:CreateLogGroup",
          //  "logs:CreateLogStream",
          //  "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

// Meets Criteria:
// CodePipeline should invalidate the CloudFront  
// Distribution after adding files to the site.
resource "aws_lambda_function" "invalidate_cloudfront" {
  filename      = "scripts/invalidate-cf.zip"
  function_name = "invalidate_cloudfront"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256("scripts/invalidate-cf.zip")

  runtime = "nodejs14.x"

  environment {
    variables = {
      cloudfront_distribution_id = aws_cloudfront_distribution.www_distribution.id
      cloudfront_region          = var.region
    }
  }
}
