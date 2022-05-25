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

resource "aws_api_gateway_stage" "api-test" {
  deployment_id = aws_api_gateway_deployment.api-test.id
  rest_api_id   = aws_api_gateway_rest_api.api-test.id
  stage_name    = "dev"
}