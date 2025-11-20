locals {
  # Create a flattened list of repo/environment pairs
  repo_environments = flatten([
    for repo_name, repo in var.repositories : [
      for env_name in repo.environments : {
        repo_name = repo_name
        env_name  = env_name
      }
    ]
  ])
}