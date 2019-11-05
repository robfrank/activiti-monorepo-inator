#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$( dirname "$0" )" && pwd)"

monorepo_dir=$SCRIPT_DIR/../activiti-monorepo-dest
git_base_url="git@github.com:Activiti"
git_branch="develop"
shopt -s extglob

# all module, cloud included
# repositories="activiti-build|Activiti|activiti-api|activiti-dependencies|activiti-core-common|activiti-cloud-api|activiti-cloud-app-service|activiti-cloud-audit|activiti-cloud-audit-service|activiti-cloud-build|activiti-cloud-connectors|activiti-cloud-dependencies|activiti-cloud-examples|activiti-cloud-gateway|activiti-cloud-modeling-build|activiti-cloud-modeling-dependencies|activiti-cloud-org-service|activiti-cloud-query-service|activiti-cloud-runtime-bundle-service|activiti-cloud-service-common"

# only build, core, commons
repositories="activiti-build|Activiti|activiti-api|activiti-dependencies|activiti-core-common|activiti-examples"

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
    if [ $repo == "activiti-examples" ] ; then 
        git merge --no-edit --allow-unrelated-histories  $repo/master
    else 
        git merge --no-edit --allow-unrelated-histories  $repo/$git_branch
    fi
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

echo "Renaming Activiti to activiti"
git mv Activiti activiti-core
git commit -m "renaming Activiti to activiti-core"

echo "copying new parent pom"
cp $SCRIPT_DIR/pom.xml $monorepo_dir

echo "fix CRLF on poms"
find . -name pom.xml -exec dos2unix {} \;

echo "fix child versions"
mvn versions:update-child-modules -DallowSnapshots=true
mvn versions:commit
git commit -m "fix child versions" .

# mvn versions:update-properties -DexcludeReactor=false -Dincludes="org.activiti, org.activiti.*" -DallowSnapshots=true -DprocessParent=true
echo "update pom properties"
mvn versions:update-properties 
git commit -m "update pom properties" .

echo "copying travis build file"
cp $SCRIPT_DIR/.gitignore $monorepo_dir
cp $SCRIPT_DIR/.travis.yml $monorepo_dir

git add .
git commit -m "add travis config" .

echo "apply patch to fix poms"
git apply -v $SCRIPT_DIR/fix-pom.patch

git commit -m "fix pom version with patch" .

cd $SCRIPT_DIR

