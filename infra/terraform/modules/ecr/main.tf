resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.tag_mutability
}