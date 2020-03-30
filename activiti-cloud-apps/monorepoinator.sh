#!/usr/bin/env bash

script_dir="$(cd "$( dirname "$0" )" && pwd)"

monorepo_dir=$script_dir/../../activiti-cloud-apps-monorepo-dest-5
git_base_url="git@github.com:Activiti"
git_branch="master"
git_dest_branch="develop"

shopt -s extglob

repositories="example-runtime-bundle|activiti-cloud-query|example-cloud-connector|activiti-cloud-acceptance-scenarios|activiti-cloud-dependencies"

files_to_delete=".dependabot,.dockerignore,.editorconfig,.helmignore,.mergify.yml,.travis.yml,.updatebot.yml,.gitignore,.codecov.yml"

echo "workdir is:: $monorepo_dir"
echo "prepare mono repo"
mkdir -p $monorepo_dir
cd $monorepo_dir

git init
touch deleteme.txt
git add deleteme.txt
git commit -m "initial commit" .
git rm deleteme.txt
git commit -m "cleanup initial file"
git checkout -b $git_dest_branch
    
echo "start merging on branch $git_dest_branch >: $repositories"

for repo in ${repositories//|/ }
do
    echo "start working on $repo"

    git remote add -f $repo $git_base_url/$repo.git
    if [ $repo == "activiti-cloud-dependencies" ] ; then
        git merge --no-edit --allow-unrelated-histories  $repo/develop
    else
        git merge --no-edit --allow-unrelated-histories  $repo/$git_branch
    fi
    mkdir $repo

    git mv ./!($repositories) ./$repo

    echo "removing unwanted files/dirs"
    for file in ${files_to_delete//,/ }
    do
        if [ -f "$file" ] || [ -d "$file" ] ; then
#            git rm -rf $file
             git mv $file ./$repo

        fi
    done    

    git commit -m "Moving $repo into its own subdirectory"

    git remote rm $repo

    echo "done $repo"

done

echo "copying new parent pom"
cp $script_dir/pom.xml $monorepo_dir
git add pom.xml
git commit -m "add parent pom" ./pom.xml
echo "---> copying new parent pom"

#echo "fix runtime bundle"
#git mv  example-runtime-bundle/charts/runtime-bundle  example-runtime-bundle/charts/example-runtime-bundle
#git commit -m "rename runtime bundle chart dir to example-runtime-bundle"
#echo "---> fix runtime bundle"

#echo "fix CRLF on poms"
#find . -name pom.xml -exec dos2unix {} \;
#git commit -m "fix CRLF on poms" .
#echo "---> fix CRLF on poms"

#echo "apply patch to disable enforcer: "
#git apply -v $script_dir/disable-enforcer.patch
#git commit -m "disbaled enforcer with patch" .
#echo "--->apply patch to disable enforcer: "


#echo "fix child versions"
#mvn versions:update-child-modules -DallowSnapshots=true
#mvn versions:commit
#git commit -m "fix child versions" .
#echo "---> fix child versions"

#echo "update pom properties"
#mvn versions:update-properties
#mvn versions:commit
#git commit -m "update pom properties" .
#echo "---> update pom properties"

#echo "apply patch to fix poms: "
#git apply -v $script_dir/disable-enforcer.patch
#git commit -m "fix pom versions with patch" .

#echo "apply patch to fix poms: revert versions"
#git apply -v $script_dir/revert-versions.patch
#git commit -m "fix pom versions with patch" .
#
#
echo "copying build configuration files"
cp -a $script_dir/conf-files/.github $monorepo_dir/
cp -a $script_dir/conf-files/.*.yml $monorepo_dir/
cp -a $script_dir/conf-files/.gitignore $monorepo_dir/
cp -a $script_dir/conf-files/.editorconfig $monorepo_dir/
cp -a $script_dir/conf-files/Jenkinsfile $monorepo_dir/
cp -a $script_dir/conf-files/Makefile $monorepo_dir/
cp -a $script_dir/conf-files/maven-dind.yaml $monorepo_dir/

#echo "add logback configuration"
#gfind $monorepo_dir -path "*/src/test" -exec mkdir -p {}/resources \;
#gfind $monorepo_dir -path "*/src/test" -exec cp -a $script_dir/conf-files/logback-test.xml {}/resources/ \;

git add .
git commit -m "add build configuration files" .

echo "workdir is:: $script_dir"
cd $script_dir

