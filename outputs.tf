output "service_role_arn" {
  description = "ARN of the GitHub Actions role for service-code"
  value       = aws_iam_role.gha_service.arn
}

output "infra_role_arn" {
  description = "ARN of the GitHub Actions role for infra-code"
  value       = aws_iam_role.gha_infra.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for the hello image"
  value       = aws_ecr_repository.hello.repository_url
}

output "update_kubeconfig_command" {
  description = "Run this to point kubectl at the cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${var.region}"
}