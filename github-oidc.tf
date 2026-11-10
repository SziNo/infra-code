# Az OIDC provider fiókonként egyszer létezik, már megvan: data-val olvassuk.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ---------- service-code szerepkör ----------

data "aws_iam_policy_document" "service_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:SziNo/service-code:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha_service" {
  name               = "${var.name}-gha-service"
  assume_role_policy = data.aws_iam_policy_document.service_trust.json
}

data "aws_iam_policy_document" "service_perms" {
  statement {
    sid       = "GetAuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushPullOwnRepo"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.hello.arn]
  }
}

resource "aws_iam_role_policy" "gha_service" {
  name   = "${var.name}-gha-service-policy"
  role   = aws_iam_role.gha_service.id
  policy = data.aws_iam_policy_document.service_perms.json
}

# ---------- infra-code szerepkör ----------

data "aws_iam_policy_document" "infra_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:SziNo/infra-code:pull_request",
        "repo:SziNo/infra-code:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "gha_infra" {
  name               = "${var.name}-gha-infra"
  assume_role_policy = data.aws_iam_policy_document.infra_trust.json
}

resource "aws_iam_role_policy_attachment" "gha_infra_admin" {
  role       = aws_iam_role.gha_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------- EKS access entry az infra szerepkörnek ----------

resource "aws_eks_access_entry" "gha_infra" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_iam_role.gha_infra.arn
}

resource "aws_eks_access_policy_association" "gha_infra" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.gha_infra.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}