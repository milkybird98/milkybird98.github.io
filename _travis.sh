#--------------------------------------------
#!/bin/bash
# author：shenliyang
# website：https://github.com/shenliyang
# slogan：梦想还是要有的，万一实现了呢。
#--------------------------------------------

#定义时间
time=`date +%Y-%m-%d\ %H:%M:%S`

#执行成功
function success(){
   echo "success"
}

#执行失败
function failure(){
   echo "failure"
}

#默认执行
function default(){

  git clone https://${GH_REF} .deploy_git
  cd .deploy_git

  git checkout master
  cd ../

  mv .deploy_git/.git/ ./public/
  cd ./public

cat <<EOF >> README.md 
# 牛乳工造
EOF

  git init
  git config user.name "milkybird98"
  git config user.email "milkybird98@outlook.com"
  git add .
  git commit -m "Build by Travis CI"
  git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:master
} 

case $1 in 
    "success")
	     success
       ;;
    "failure")
	     failure
	     ;;
	         *) 
       default	
esac

