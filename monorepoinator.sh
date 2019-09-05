#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$( dirname "$0" )" && pwd)"

monorepo_dir=$SCRIPT_DIR/../activiti-monorepo-dest
git_base_url="git@github.com:Activiti"
git_branch="develop"
shopt -s extglob

repositories="activiti-build|Activiti|activiti-api|activiti-dependencies|activiti-core-common|activiti-cloud-api|activiti-cloud-app-service|activiti-cloud-audit|activiti-cloud-audit-service|activiti-cloud-build|activiti-cloud-common-chart|activiti-cloud-connectors|activiti-cloud-dependencies|activiti-cloud-examples|activiti-cloud-full-chart|activiti-cloud-gateway|activiti-cloud-modeling-build|activiti-cloud-modeling-dependencies|activiti-cloud-org-service|activiti-cloud-query-service|activiti-cloud-runtime-bundle-service|activiti-cloud-service-common"

files_to_delete=".dependabot,.dockerignore,.editorconfig,.helmignore,.mergify.yml,.travis.yml,.updatebot.yml,.gitignore,.codecov.yml"

echo "prepare mono repo"

mkdir -p $monorepo_dir
cd $monorepo_dir

git init
touch deleteme.txt
git add deleteme.txt
git commit -m "initial commit" .
git rm deleteme.txt
git commit -m "cleanup initial file"
git checkout -b develop
    
echo "start merging: $repositories"

for repo in ${repositories//|/ }
do
    echo "start working on $repo"

    git remote add -f $repo $git_base_url/$repo.git
    git merge --no-edit --allow-unrelated-histories  $repo/$git_branch

    mkdir $repo

    git mv ./!($repositories) ./$repo

    echo "removing unwanted files/dirs"
    for file in ${files_to_delete//,/ }
    do
        if [ -f "$file" ] || [ -d "$file" ] ; then
            git rm -rf $file
        fi        
    done    
    git commit -m "Moving $repo into its own subdirectory"
   
    echo "done $repo"

done

echo "copying new parent pom"
cd $SCRIPT_DIR
cp $SCRIPT_DIR/pom.xml $monorepo_dir
