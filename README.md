# Continuous deployment using CircleCI and Github.

## X. Generate SSH deploy keys.

This needs to be done once per organisation/team, so you can share the deploy keys over all repositories that share the same target deployment servers.

```
# Creates files deploy and deploy.pub in your current directory.
ssh-keygen -t rsa -b 4096 -C deploy@circleci -f deploy
```

## X. Add `circle.yml` configuration file to your repo.

After any `machine`, `checkout`, `dependencies`, etc., add the `deployment` commands for matching branches/tags you want to deploy.

```
deployment:
  issue:
    branch: /([0-9]+-.*)/
    commands:
      - ./deploy issue

  staging:
    branch: master
    commands:
      - ./deploy staging

  production:
    tag: /(v[0-9]\.[0-9]\.[0-9])/
    commands:
      - ./deploy production
```