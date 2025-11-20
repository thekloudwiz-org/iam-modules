output "repository_names" {
  description = "Names of the created repositories"
  value       = [for repo in github_repository.repos : repo.name]
}

output "repository_urls" {
  description = "URLs of the created repositories"
  value = {
    for name, repo in github_repository.repos : name => repo.html_url
  }
}