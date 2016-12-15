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

## X. Configure non-tracked files.

There are two supported methods for handling non-tracked files, such as configuration and other files that only exist in certain forms on a server-by-server basis. Configuration files are the most obvious requirement here, as they need to contain information such as API secret keys, database passwords, etc. and this information should never find its way into version control.

### Full file overwrites.

Certain files that need to exist on particular servers can be placed in `/var/deploy/files/REPO_NAME`. The files will be coppied over the repository after deployment, overwriting whatever is in its place. For example, when deploying the master branch to `/var/www/REPO_NAME/master`, placing a file at `/var/deploy/files/REPO_NAME/config/database.ini` will copy the file to `/var/www/REPO_NAME/master/config/database.ini`, and any file in its place will be overwritten.

### Configuration file placeholders.

Sometimes it is a better strategy to replace only certain values within files. This is especially useful for configuration files; each server may share all configuration options apart from one, and it would make more sense to only update the lines that are different per server.

This is achieved by placing configuration files within `/var/deploy/config/REPO_NAME`. Each type of file's replacement is handled differently. Only place the updated lines witin the files, in the same layout as they should be copied, as per full file overwrites.

For example, if the `database.ini` file only needs its hostname and password changing per server, the following file contents can be used, which will replace the matching lines:

```ini
hostname="db.example.com"
password="t0ps3cr3t"
```

All existing lines in the matching files will be kept in place. This placeholder updating method merges `ini`, `json` and `yml` config files.

## X. Run the deploy script from CircleCI.

To execute the deployment, the `deploy` bash script should be executed within the CircleCI builds. The way you get the script itself distributed onto your build servers is up to you, but one method would be to configure CircleCI to download the script from Github before the deployment stage, then run it through bash.

```yml
checkout:
  post:
    - wget https://raw.githubusercontent.com/g105b/circleci-github-deploy/master/deploy.sh

deployment:
  issue:
    branch: /([0-9]+-.*)/
    commands:
      - bash deploy.sh issue

  staging:
    branch: master
    commands:
      - bash deploy.sh staging

  production:
    tag: /(v[0-9]\.[0-9]\.[0-9])/
    commands:
      - bash deploy.sh production
```