# Continuous deployment using CircleCI and Github.

## X. Generate SSH deploy keys.

This needs to be done once per organisation/team, so you can share the deploy keys over all repositories that share the same target deployment servers.

```bash
# Creates files deploy-key and deploy-key.pub in your current directory.
ssh-keygen -t rsa -b 4096 -C deploy@circleci -f deploy-key
```

## X. Distribute SSH deploy keys.

The public key (`deploy-key.pub`) can be added to the `authorized_keys` file on all live/staging servers.

The private key (`deploy-key`) can be added to the SSH Permissions of CircleCI by going to **Project Settings** -> **Permissions** -> **SSH Permissions**.

Add each hostname that will be used in deployment individually to the SSH Permissions page, e.g. production.srv.my-organisation.com, test-env.srv.my-organisation.com.

## X. Add `circle.yml` configuration file to your repo.

After any `machine`, `checkout`, `dependencies`, etc., add the `deployment` commands for matching branches/tags.

The `issue`, `staging` and `production` sub-keys must match the deploy script to differentiate types of deployment.

```yml
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

Each command executes the `deploy` script with the argument `issue`, `staging` or `production`. Branch/tag/path information is provided by CircleCI via environment variables.