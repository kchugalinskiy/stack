variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "path" {
  description = "The path of the stack to use in security groups"
  default = "/"
}

variable "allow_services" {
  description = ""
  default     = "\"ec2.amazonaws.com\""
}

variable "inline_policy" {
  type = "string"
  default = ""
}

data "template_file" "aws_iam_role" {
  template = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          $${allow_services}
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  vars {
    allow_services = "${var.allow_services}"
  }
}

resource "aws_iam_role_policy" "inline_policy" {
  name = "inline-policy-${var.name}"
  role = "${aws_iam_role.instance_role.id}"

  policy = "${var.inline_policy}"

  count = "${var.inline_policy == "" ? 0 : 1}"
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.name}"
  path               = "${var.path}"
  assume_role_policy = "${data.template_file.aws_iam_role.rendered}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  roles = ["${aws_iam_role.instance_role.name}"]
}

output "arn" {
  value = "${aws_iam_role.instance_role.arn}"
}

output "profile" {
  value = "${aws_iam_instance_profile.instance_profile.id}"
}

