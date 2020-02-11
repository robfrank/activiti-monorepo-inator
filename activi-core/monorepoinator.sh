#!/usr/bin/env bash

script_dir="$(cd "$( dirname "$0" )" && pwd)"

monorepo_dir=$script_dir/../activiti-monorepo-dest-2
git_base_url="git@github.com:Activiti"
git_branch="develop"
git_dest_branch="develop-mono"

shopt -s extglob

# all module, cloud included
# repositories="activiti-build|Activiti|activiti-api|activiti-dependencies|activiti-core-common|activiti-cloud-api|activiti-cloud-app-service|activiti-cloud-audit|activiti-cloud-audit-service|activiti-cloud-build|activiti-cloud-connectors|activiti-cloud-dependencies|activiti-cloud-examples|activiti-cloud-gateway|activiti-cloud-modeling-build|activiti-cloud-modeling-dependencies|activiti-cloud-org-service|activiti-cloud-query-service|activiti-cloud-runtime-bundle-service|activiti-cloud-service-common"

# only build, core, commons
repositories="activiti-build|Activiti|activiti-api|activiti-dependencies|activiti-core-common|activiti-examples"

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

    git remote rm $repo

    echo "done $repo"

done

echo "Renaming Activiti to activiti-core"
git mv Activiti activiti-core
git commit -m "renaming Activiti to activiti-core"
echo "move files back form core to project root dir"
git mv activiti-core/CODE_OF_CONDUCT.md  ./
git mv activiti-core/README.md  ./
git mv activiti-core/CONTRIBUTING.md	 ./
git mv activiti-core/checkstyle-rules.xml	 ./
git mv activiti-core/LICENSE.txt	 ./
git mv activiti-core/activiti7.png	 ./
git commit -m "move files back form core to project root dir"

echo "copying new parent pom"
cp $script_dir/pom.xml $monorepo_dir
git add pom.xml
git commit -m "add parent pom" ./pom.xml

echo "fix CRLF on poms"
find . -name pom.xml -exec dos2unix {} \;
git commit -m "fix CRLF on poms" .

echo "fix child versions"
mvn versions:update-child-modules -DallowSnapshots=true
mvn versions:commit
git commit -m "fix child versions" .

echo "update pom properties"
mvn versions:update-properties 
mvn versions:commit
git commit -m "update pom properties" .

#echo "apply patch to fix poms"
#git apply -v $script_dir/fix-pom.patch
#git commit -m "fix pom versions with patch" .

echo "apply second patch to fix poms"
git apply -v $script_dir/fix-pom-new.patch
git commit -m "fix pom versions with patch" .

echo "copying build configuration files"
cp -a $script_dir/conf-files/.github $monorepo_dir/
cp -a $script_dir/conf-files/.*.yml $monorepo_dir/
cp -a $script_dir/conf-files/Jenkinsfile $monorepo_dir/
cp -a $script_dir/conf-files/Makefile $monorepo_dir/
git add .
git commit -m "add build configuration files" .

echo "workdir is:: $script_dir"
cd $script_dir

