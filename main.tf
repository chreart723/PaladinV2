provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "Paladin0.2.0"
      Purpose = "deployAppInTF"
    }
  }
}

resource "aws_lambda_function" "myLambdaFunction" {
  function_name = var.lambda_function_name
  runtime       = "python3.9"
  role          = aws_iam_role.myLambdaRole.arn
  handler       = "main.lambda_handler"
  filename      = "zipped_python_program.zip"
  depends_on = [
    aws_iam_role_policy_attachment.myAttachPolicyToRole,
    aws_cloudwatch_log_group.myLogwatchGroup,
  ]
}

resource "aws_cloudwatch_log_group" "myLogwatchGroup" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "myDNDLambdaPolicy" {
  name        = "myDNDLambdaPolicy1"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "myAttachPolicyToRole" {
  role       = aws_iam_role.myLambdaRole.name
  policy_arn = aws_iam_policy.myDNDLambdaPolicy.arn
}

resource "aws_iam_role" "myLambdaRole" {
  name               = "lambda_role"
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

resource "aws_api_gateway_rest_api" "my_DND-apigw" {
  name = "my_DND-apigw"
}

resource "aws_api_gateway_resource" "myAPIgwResource" {
  rest_api_id = aws_api_gateway_rest_api.my_DND-apigw.id
  parent_id   = aws_api_gateway_rest_api.my_DND-apigw.root_resource_id
  path_part   = var.endpoint_path
}

resource "aws_api_gateway_method" "myAPIgwMethod" {
  rest_api_id   = aws_api_gateway_rest_api.my_DND-apigw.id
  resource_id   = aws_api_gateway_resource.myAPIgwResource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "myAPIgwIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.my_DND-apigw.id
  resource_id             = aws_api_gateway_resource.myAPIgwResource.id
  http_method             = aws_api_gateway_method.myAPIgwMethod.http_method
  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.myLambdaFunction.invoke_arn
}

resource "aws_lambda_permission" "myLambdaPermission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.myLambdaFunction.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.accountID}:${aws_api_gateway_rest_api.my_DND-apigw.id}/*/${aws_api_gateway_method.myAPIgwMethod.http_method}${aws_api_gateway_resource.myAPIgwResource.path}" 
}

resource "aws_api_gateway_deployment" "myAPIgwDeploy" {
  rest_api_id = aws_api_gateway_rest_api.my_DND-apigw.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.my_DND-apigw.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_method.myAPIgwMethod,
    aws_api_gateway_integration.myAPIgwIntegration,
  ]
}

resource "aws_api_gateway_stage" "myAPIgwStage" {
  deployment_id = aws_api_gateway_deployment.myAPIgwDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.my_DND-apigw.id
  stage_name    = "dev"
}
