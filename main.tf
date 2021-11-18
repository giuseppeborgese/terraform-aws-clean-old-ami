resource "aws_iam_role" "clean_old_ami" {
  name = "${var.prefix}_clean_old_ami"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy" "clean_old_ami" {
  name = "${var.prefix}_clean_old_ami"
  role = "${aws_iam_role.clean_old_ami.id}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ec2:DeregisterImage"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}


resource "aws_iam_role_policy" "allowcloudwatchlogging" {
  name = "${var.prefix}_Enable_login"
  role = "${aws_iam_role.clean_old_ami.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "clean_old_ami" {
    role = "${aws_iam_role.clean_old_ami.id}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}




variable "filename" {  default = "package" }
resource "aws_lambda_function" "clean_old_ami" {
  filename         = "${path.module}/${var.filename}.zip"
  source_code_hash = filebase64("${path.module}/${var.filename}.zip")
  function_name    = "${var.prefix}_clean_old_ami"
  role             = "${aws_iam_role.clean_old_ami.arn}"
  handler          = "${var.filename}.lambda_handler"
  runtime          = "python3.7"
  publish          = "true"
  timeout          = 300
  memory_size      = 128
  description      = "This function run inside a vpc, download the s3 files for that vpc and try to run http/s queries to check if the proxy does his job"

  environment {
    variables = {
      TAG_FILTER             = "${var.tag_filter}"
      DELETE_OLDER_THAN_DAYS = "${var.delete_older_than_days}"
      EXCLUSION_TAG          = "${var.exclusion_tag}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "clean_old_ami" {
    name = "${var.prefix}.every-day-run-an-cleaning"
    description = "Fires every month"
    schedule_expression = "cron(0 9 1 * ? *)"  #shoulb be called each month the 1st day at 9 in the morning
}

resource "aws_cloudwatch_event_target" "clean_old_ami" {
    rule = "${aws_cloudwatch_event_rule.clean_old_ami.name}"
    target_id = "${var.prefix}_clean_old_ami"
    arn = "${aws_lambda_function.clean_old_ami.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_clean_old_ami" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.clean_old_ami.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.clean_old_ami.arn}"
}
