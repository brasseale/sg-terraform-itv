resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    // We need to set up a "custom" origin because otherwise CloudFront won't
    // redirect traffic from the root domain to the www domain, that is from
    // runatlantis.io to www.runatlantis.io.
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    // Here we're using our S3 bucket's URL!
    domain_name = aws_s3_bucket.b.website_endpoint
    // This can be any name to identify this origin.
    origin_id = local.domain_name
  }

  enabled             = true
  default_root_object = "index.html"

  // All values are defaults from the AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    // This needs to match the `origin_id` above.
    target_origin_id = local.domain_name

    // Meets criteria:
    // Amazon CloudFront’s default behavior should be configured to not cache.
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/images/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.domain_name

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    // Meets Criteria:
    // Amazon CloudFront should have an additional behavior configured to 
    // cache an image for a default / minimum / maximum TTL = 30 minutes.
    min_ttl                = 1800
    default_ttl            = 1800
    max_ttl                = 1800
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // SSL CERT - Default

  // Meets Criteria:
  // Amazon CloudFront should have SSL enabled using
  // the Default CloudFront Certificate.
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}



