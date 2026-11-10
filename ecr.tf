resource "aws_ecr_repository" "hello" {
  name                 = "${var.name}/hello"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  tags = {
    Name = "${var.name}/hello"
  }
}