variable "stage_name" {
  default = "dev"

}
resource "aws_api_gateway_rest_api" "api-test" {
  name = "api-test"
}

resource "aws_api_gateway_resource" "api-test" {
  parent_id   = aws_api_gateway_rest_api.api-test.root_resource_id
  path_part   = "user"
  rest_api_id = aws_api_gateway_rest_api.api-test.id
}

resource "aws_api_gateway_method" "api-test" {
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.api-test.id
  rest_api_id      = aws_api_gateway_rest_api.api-test.id
  api_key_required = true
}

resource "aws_api_gateway_method_settings" "api-test" {
  depends_on  = [aws_api_gateway_account.role_cloudwatch_gateway, aws_api_gateway_stage.api-test]
  rest_api_id = aws_api_gateway_rest_api.api-test.id
  stage_name  = var.stage_name
  method_path = "*/*"
  settings {
    data_trace_enabled = true
    metrics_enabled    = true
    logging_level      = "ERROR"
  }
}

resource "aws_api_gateway_integration" "api-test" {
  http_method = aws_api_gateway_method.api-test.http_method
  resource_id = aws_api_gateway_resource.api-test.id
  rest_api_id = aws_api_gateway_rest_api.api-test.id
  type        = "MOCK"
}

resource "aws_api_gateway_deployment" "api-test" {
  rest_api_id = aws_api_gateway_rest_api.api-test.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api-test.id,
      aws_api_gateway_method.api-test.id,
      aws_api_gateway_integration.api-test.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "access-log" {
  depends_on        = [aws_kms_key.kms_for_cloudwatch]
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api-test.id}/${var.stage_name}"
  retention_in_days = 1
  kms_key_id        = aws_kms_key.kms_for_cloudwatch.arn
}


resource "aws_api_gateway_stage" "api-test" {
  depends_on    = [aws_cloudwatch_log_group.access-log, aws_api_gateway_account.role_cloudwatch_gateway]
  deployment_id = aws_api_gateway_deployment.api-test.id
  rest_api_id   = aws_api_gateway_rest_api.api-test.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access-log.arn
    format          = <<-EOT
                { "requestId":"$context.requestId",
                  "extendedRequestId":"$context.extendedRequestId",
                  "ip": "$context.identity.sourceIp",
                  "caller":"$context.identity.caller",
                  "user":"$context.identity.user",
                  "requestTime":"$context.requestTime",
                  "httpMethod":"$context.httpMethod", \
                  "resourcePath":"$context.resourcePath",
                  "status":"$context.status",
                  "protocol":"$context.protocol",
                  "responseLength":"$context.responseLength"
                }
            EOT


  }
  xray_tracing_enabled = true

}

resource "aws_api_gateway_account" "role_cloudwatch_gateway" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}