# ./modules/iam/iam.tf

# Create an openid connect provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    "6938fd4d98bab03faadb97b34396831e3780aea1"
    ]
}

# TODO: Reduce access
# Create an IAM policy
data "aws_iam_policy_document" "github_policy" {
  statement {
    actions = [
        "s3:*",
        "cloudfront:*",
        "route53:*",
        "dynamodb:*",
        "apigateway:*",
        "lambda:*",
        "iam:*"
        ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "github_iam_policy" {
  name = "github"
  policy = data.aws_iam_policy_document.github_policy.json
}


data "aws_iam_policy_document" "github_role_assume_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:StephenDryden/workflow:*",
        "repo:StephenDryden/stephendryden.co.uk-frontend:*",
        "repo:StephenDryden/workflow-iam:*",
        "repo:StephenDryden/todo:*",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

# Create an IAM role
resource "aws_iam_role" "github_role" {
  name = "github"
  assume_role_policy = data.aws_iam_policy_document.github_role_assume_policy.json
}

# Attach the IAM policy to the IAM role
resource "aws_iam_policy_attachment" "github_role_policy_attachment" {
  name = "Policy Attachement"
  policy_arn = aws_iam_policy.github_iam_policy.arn
  roles       = [aws_iam_role.github_role.name]
}
