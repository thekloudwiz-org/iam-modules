locals {
  policies = {
    # Deployment permissions (split due to size limits)
    deployment_part1 = {
      name        = "${var.project_name}-deployment-permissions-1"
      description = "Deployment permissions - Part 1 (S3, DynamoDB, IAM, EC2)"
      path        = "/"
      policy_file = "${path.root}/policies/deployment-permissions-1.json"
    }

    deployment_part2 = {
      name        = "${var.project_name}-deployment-permissions-2"
      description = "Deployment permissions - Part 2 (Container and Infrastructure Services)"
      path        = "/"
      policy_file = "${path.root}/policies/deployment-permissions-2.json"
    }

    deployment_part3 = {
      name        = "${var.project_name}-deployment-permissions-3"
      description = "Deployment permissions - Part 3 (CI/CD and Database Services)"
      path        = "/"
      policy_file = "${path.root}/policies/deployment-permissions-3.json"
    }

    deployment_part4 = {
      name        = "${var.project_name}-deployment-permissions-4"
      description = "Deployment permissions - Part 4 (Analytics, Billing, Auth, Security, API, Messaging)"
      path        = "/"
      policy_file = "${path.root}/policies/deployment-permissions-4.json"
    }

    deployment_part5 = {
      name        = "${var.project_name}-deployment-permissions-5"
      description = "Deployment permissions - Part 5 (IoT, Events, Backup, Monitoring, Cache, Resources)"
      path        = "/"
      policy_file = "${path.root}/policies/deployment-permissions-5.json"
    }

    # Read-only policy for pull requests
    readonly = {
      name        = "${var.project_name}-read-only-permissions"
      description = "Read-only permissions for pull requests"
      path        = "/"
      policy_file = "${path.root}/policies/read-only-permissions.json"
    }

    # Wildcard policy for development environments
    wildcard = {
      name        = "${var.project_name}-wildcard-permissions"
      description = "Wildcard permissions for development environments"
      path        = "/"
      policy_file = "${path.root}/policies/wildcard-permissions.json"
    }
  }
}