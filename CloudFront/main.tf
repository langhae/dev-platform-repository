resource "aws_cloudfront_cache_policy" "this" {
  name        = "multi05-policy"
  comment     = "my custom policy"
  default_ttl = 1
  max_ttl     = 31536000
  min_ttl     = 86400
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip = true
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "Create new identity"
}


resource "aws_cloudfront_distribution" "this" {
  # ... other configuration ...

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    origin_path = "/iot"
      
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }
  
  aliases             = "d604721fxaaqy9.cloudfront.net"
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "my distribution"
  
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    viewer_protocol_policy = "allow-all"
    target_origin_id = local.s3_origin_id
    cache_policy_id = local.cache_policy_id
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }
  
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn = "arn:aws:acm:us-east-1:940168446867:certificate/7ce5554b-b489-4de5-a393-02ee0d00c9e1"
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }

}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.s3_policy.json
}


resource "aws_s3_bucket" "this" {
  bucket = "langhae-cloudfront-20220608"

  tags = {
    Name = "langhae-cloudfront-20220608"
  }
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

locals {
  cache_policy_id = aws_cloudfront_cache_policy.this.id
  s3_origin_id = "myS3Origin"
}
