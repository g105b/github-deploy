# Continuous deployment using CircleCI and Github.

## X. Generate SSH deploy keys.

This needs to be done once per organisation/team, so you can share the deploy keys over all repositories that share the same target deployment servers.

```
# Creates files deploy and deploy.pub in your current directory.
ssh-keygen -t rsa -b 4096 -C deploy@circleci -f deploy
```