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

## X. Set up server links.

On each production and staging server, the repositories that will be deployed need their deploy locations linking. This is done by placing a symlink at `/var/deploy/REPO_NAME`.

For example on a production server, when a tag's distribution files are sent to the server, they will be placed directly in `/var/deploy/REPO_NAME`. This can be a symbolic link to anywhere else on disk, commonly `/var/www/example.com`.

On staging servers (initiated from matching branches or the master branch), the same is true except the branch name will be appended to the path.

For example on a staging server, when the master branch's distribution files are sent to the server, they will be placed into `/var/deploy/REPO_NAME/master`. The same goes for other branches. This allows a webserver to be set up to serve all branches using a subdomain convention such as master.staging.example.com .