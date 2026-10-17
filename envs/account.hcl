# /envs/account.hcl

# Account-wide variables, read by envs/pred/plt/poc/root.hcl and
# envs/main/plt/poc/root.hcl.
locals {
  # Replace with your AWS account ID before first apply. Keep the real value
  # local: `git update-index --skip-worktree envs/account.hcl`.
  # Every provider is pinned to this ID via allowed_account_ids, so a wrong
  # AWS profile fails fast instead of creating resources in another account.
  aws_account_id = "111122223333"
}
