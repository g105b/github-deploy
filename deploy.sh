#!/bin/bash
if [ $# -lt 1 ];
then
	echo "Error: Not enough arguments."
	echo "Usage: deploy production|staging|issue"
	exit 1
fi

CFG_TMP_PATH="/tmp/deploy"
CFG_DEPLOY_BASE_PATH="/var/deploy"
CFG_DEPLOY_BASE_PATH_PROD="$CFG_DEPLOY_BASE_PATH"
CFG_FILES_PATH="/var/deploy/files"
CFG_FILES_PATH_PROD="$CFG_FILES_PATH"

# Overwrite the configurable variables with any set in config.ini .
if [ -a config.ini ]; then
	VALUE=$(awk -F "=" '/deploy_tmp_path/ {print $2}' config.ini)
	if [ ! -z $VALUE ]; then
		CFG_TMP_PATH=$VALUE
	fi

	VALUE=$(awk -F "=" '/deploy_base_path/ {print $2}' config.ini)
	if [ ! -z $VALUE ]; then
		CFG_DEPLOY_BASE_PATH=$VALUE
	fi

	VALUE=$(awk -F "=" '/deploy_base_path_prod/ {print $2}' config.ini)
	if [ ! -z $VALUE ]; then
		CFG_DEPLOY_BASE_PATH_PROD=$VALUE
	fi

	VALUE=$(awk -F "=" '/deploy_files_path/ {print $2}' config.ini)
	if [ ! -z $VALUE ]; then
		CFG_FILES_PATH=$VALUE
	fi

	VALUE=$(awk -F "=" '/deploy_files_path_prod/ {print $2}' config.ini)
	if [ ! -z $VALUE ]; then
		CFG_FILES_PATH_PROD=$VALUE
	fi
fi

DEPLOY_TYPE_TAG="deploy-type-tag"
DEPLOY_TYPE_BRANCH="deploy-type-branch"
DEPLOY_TYPE=""
DEPLOY_REF=""
DEPLOY_PATH="$CFG_DEPLOY_BASE_PATH/$CIRCLE_PROJECT_REPONAME"

case $1 in
"production")
	DEPLOY_TYPE=$DEPLOY_TYPE_TAG
	DEPLOY_REF="$CIRCLE_TAG"
	DEPLOY_PATH="$CFG_DEPLOY_BASE_PATH_PROD/$CIRCLE_PROJECT_REPONAME"
	CFG_FILES_PATH="$CFG_FILES_PATH_PROD"
	;;
"staging")
	DEPLOY_TYPE=$DEPLOY_TYPE_BRANCH
	DEPLOY_REF="master"
	DEPLOY_PATH="$DEPLOY_PATH/$DEPLOY_REF"
	;;
"issue")
	DEPLOY_TYPE=$DEPLOY_TYPE_BRANCH
	DEPLOY_REF="$CIRCLE_BRANCH"
	DEPLOY_PATH="$DEPLOY_PATH/$DEPLOY_REF"
	;;
*)
	echo "Invalid deployment type '$1'."
	exit 1
	;;
esac

case $DEPLOY_TYPE in
$DEPLOY_TYPE_TAG)
	SSH_CONNECTION=$(awk -F "=" '/ssh_production/ {print $2}' config.ini)
	;;
$DEPLOY_TYPE_BRANCH)
	SSH_CONNECTION=$(awk -F "=" '/ssh_staging/ {print $2}' config.ini)
	;;
esac

# stream to tmp directory first; this avoids downtime during stream.
TMPDIR=CFG_TMP_PATH
REMOTE_SSH_TAR_COMMAND="rm -rf $TMPDIR; mkdir -p $TMPDIR; cd $TMPDIR; tar xzf -"
CMD_SSH_TAR="ssh $SSH_CONNECTION '$REMOTE_SSH_TAR_COMMAND'"
# Circle will execute this script within the repo directory.
cd ..
# Perform tar stream. "-" file indicates a redirect via pipe.
echo "Executing: tar czf - '$CIRCLE_PROJECT_REPONAME/' | eval $CMD_SSH_TAR"
tar czf - "$CIRCLE_PROJECT_REPONAME/" | eval $CMD_SSH_TAR

# Copy any deployment files over the new deployment.
DEPLOY_FILES_PATH="$CFG_FILES_PATH/$CIRCLE_PROJECT_REPONAME"
CMD_SSH_FILES="cp -R $DEPLOY_FILES_PATH/* $TMPDIR/$CIRCLE_PROJECT_REPONAME"
# Make a backup of the old deployment.
CMD_BACKUP="if [ -d $DEPLOY_PATH ]; then rm -rf $DEPLOY_PATH.old; mv $DEPLOY_PATH $DEPLOY_PATH.old; fi"
# Move the completed stream to the correct deploy path.
CMD_MOVE_DEPLOYMENT="mkdir -p $DEPLOY_PATH; mv $TMPDIR/$CIRCLE_PROJECT_REPONAME/* $DEPLOY_PATH"

echo "Remotely executing: $CMD_SSH_FILES"
echo "Remotely executing: $CMD_BACKUP"
echo "Remotely executing: $CMD_MOVE_DEPLOYMENT"

# Perform all commands in one connection to minimise downtime.
eval "ssh $SSH_CONNECTION '$CMD_SSH_FILES; $CMD_BACKUP; $CMD_MOVE_DEPLOYMENT'"