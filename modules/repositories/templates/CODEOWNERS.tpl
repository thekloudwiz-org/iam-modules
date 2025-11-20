# This file defines code owners for the repository
# Code owners are automatically requested for review when someone opens a PR that modifies code they own
# Learn more at https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners

# Default owners for everything in the repo
%{if length(default_owners) > 0}
* ${join(" ", [for owner in default_owners : "@${owner}"])}
%{endif}

# Owners for specific paths
%{for path, owners in path_owners}
${path} ${join(" ", [for owner in owners : "@${owner}"])}
%{endfor}