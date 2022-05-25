resource "aws_api_gateway_api_key" "api-test-api-key" {
  name = "api-test-api-key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  depends_on    = [aws_api_gateway_api_key.api-test-api-key, aws_api_gateway_usage_plan.api-test-usage-plan]
  key_id        = aws_api_gateway_api_key.api-test-api-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api-test-usage-plan.id
}