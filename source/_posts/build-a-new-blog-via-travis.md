---
title: 使用 Travis CI 自动部署 HEXO 博客到 GitHub
date: 2018-04-07 14:58:35
categories: TECH
tags: 
  - ci
  - guide
---
本来只是想给博客换个主题（旧的主题引用的某个js源炸了，懒得改代码，于是决定重新换个主题），但是翻着翻着就发现了个叫 [Tarvis CI](https://travis-ci.org/) 的好玩的网站，（突然感觉自己弱爆了，以前居然连这种东西都不知道），于是打算折腾一通，试一试感觉如何。最终的结论是，效率提升≈0，逼格提升≈1000000（穷人，只有一台电脑，不存在环境问题）。

无论如何，写篇博客记录一下吧（理论上这篇博客也是 Tarvis CI 托管生成的）。

# 准备阶段

## Tarvis

你要用 Tarvis ，好歹得有个账号吧，所幸 Tarvis 和 GitHub 关系比较~~暧昧~~特殊，可以直接用GitHub账号登陆；（请猛击那个Sign in with GayHub）
![Login](/images/Snipaste_2018-04-07_15-17-04.jpg)
之后就需要选择自动生成哪些repo；
![repo](/images/Snipaste_2018-04-07_15-21-55.jpg)
在Tarvis的操作目前到此为止，但我们之后还是要回来的。

***

## GitHub

### 仓库：

首先先把博客的 repo clone 到本地来，然后签出一个新的分支（叫 dev 还是什么其他看个人兴趣，我的叫 hexo ，这个就不放图了啊），这个分支用于保存博客的 raw 文件，渲染之后再将其push到master分支，这样的话不需要新开一个 repo 。

然后，重头戏，把这个 branch 里的文件给删！光！光！然后再把本地用于生成博客的文件拷贝进来，然后push（别忘记创建远程分支）。

之后就应该是这样

![branch](/images/Snipaste_2018-04-07_15-29-12.jpg)

- master分支用于存放 *渲染完的博客网页文件* 。
- hexo分支用于存放 *用于渲染博客的文件* 。

### 密钥：

然后我们还需要一个让 Tarvis 的服务器能够向我们在 GitHub 上 Push 代码的凭证。但是问题在于，我们博客的仓库是开源的，如果将密钥或是其他的什么直接明文存储，呵呵。。。

所以我们需要一个加密存储的方式，Tarvis 上可用的有两种：

- 使用 ssh key
- 使用 Tarvis 的环境变量来存储 GitHub Token

我这里选择了第二种（一般来说第一种安全些，各位可以从网上参照一下）。

在个人设置里面，

![setting](/images/Snipaste_2018-04-07_15-38-12.jpg)

新建一个新的个人 token ，

![token](/images/Snipaste_2018-04-07_15-38-28.jpg)
![token1](/images/Snipaste_2018-04-07_15-38-47.jpg)

token 需要给予 repo 的控制权限，记得在创建完成后复制生成的 token ，之后是无法查询到这个 token 的数值的。

![token2](/images/Snipaste_2018-04-07_15-39-49.jpg)

然后我们需要重新回到 [Tarvis](https://travis-ci.org/) , 点击你激活的那个   repo 左边的齿轮图标进入设置界面，将我们刚刚拿到的 token 设置为环境变量。

![env_token](/images/Snipaste_2018-04-07_15-49-19.jpg)

至此，准备工作彻底完毕，接下来就要开始~~掉头发~~码代码了。

# 具体配置

## ".travis.yml"

请在当前本地仓库的 hexo 分支根目录下创建如章节名称的文件（注意以 "." 开头），然后用代码编辑器打开这个文件（废话），关于这个文件的编写可以参照这篇博客：[持续集成服务 Travis CI 教程](http://www.ruanyifeng.com/blog/2017/12/travis_ci_tutorial.html)。

```yml
# 选择使用的语言
language: node_js
node_js: stable

sudo: false

# 为了提速，我们在这里使用缓存来把node的package都保存下来
cache:
  directories:
    - "node_modules"

# Tarvis 给你发提醒的配置
notifications:
  # 我们选择使用邮件
  email:
    recipients:
    # 你的邮件地址
      - youremail@xxx.com
    # 是否在成功时发生邮件
    on_success: never
    # 是否在失败时发送邮件
    on_failure: always

# S: Build Lifecycle
install:
  - npm install

before_script:
  - export TZ='Asia/Shanghai'
  - chmod +x _travis.sh

# hexo标准操作，注意没有"hexo d"，即不进行部署
script:
  - hexo clean && hexo g

after_success:

# 没有这个文件？有才见了鬼，这个文件我们待会手写!
after_script:
  - ./_travis.sh

# E: Build LifeCycle

# 选择进行操作的分支，即 Tarvis 需要监测和处理的分支，也可以使用黑白名单，用法请自行Google
branches:
  only:
    - hexo

# 设置环境变量，注意这里的环境变量是没有加密的
env:
 global:
    # 你的GitHub地址
   - GH_REF: github.com/milkybird98/milkybird98.github.io.git
```

博主本人也是自行摸索+借鉴，有可能在设置上存在问题，还请指出（可以在GitHub上留个issue之类的）。

***

## "_travis.sh"

在 ".tarvis.yml" 里面我们没有执行 "hexo d" 命令，因为我们需要手动部署。（这一段是直接使用的shenliyang大大的代码，在此感谢shenliyang大大）

Ps. 貌似可以用 hexo 的 deploy，各位可以去研究一下

```sh
#--------------------------------------------
# !/bin/bash
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
部署状态 | 集成结果 | 参考值
---|---|---
完成时间 | $time | yyyy-mm-dd hh:mm:ss
部署环境 | $TRAVIS_OS_NAME + $TRAVIS_NODE_VERSION | window \| linux + stable
部署类型 | $TRAVIS_EVENT_TYPE | push \| pull_request \| api \| cron
启用Sudo | $TRAVIS_SUDO | false \| true
仓库地址 | $TRAVIS_REPO_SLUG | owner_name/repo_name
提交分支 | $TRAVIS_COMMIT | hash 16位
提交信息 | $TRAVIS_COMMIT_MESSAGE |
Job ID   | $TRAVIS_JOB_ID |
Job NUM  | $TRAVIS_JOB_NUMBER |
EOF

  git init
  # 输入你自己的GitHub的name和email
  git config user.name "milkybird98"
  git config user.email "milkybird98@outlook.com"
  git add .
  git commit -m "Build by Travis CI"
  # ${GH_TOKEN}替换为你设定的 token 的环境变量名称${xxxx}，${GH_REF}是在上一节中设定的
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
```

至此，文件上的处理就完成了，现在只需要把 hexo 分支的代码 push 一次， Tarvis CI那边检测到 request 后就会自动去进行处理。

***

## 坑

- 问题：如果你出现了 build 成功但是博客打开后却是一片白，或者远程仓库里主题文件夹一片空白（一般情况是连theme文件夹都没有）；
- 解决：使用如下指令而非clone，将主题的仓库作为子模块使用，或者直接将主题的仓库变为普通的本地代码。

```sh
git add submodule git://github.com/xxxxxxxxxx/xxxxxxxx.git theme/${你的主题名称}/
```

- 问题：build 成功但是仓库的 master 分支没有变化；
- 解决：请确定你输入的 token 是否正确（其实根本没法确认，删掉旧的再申请个新的吧），以及权限是否正确。

***

## Tips

### 可以将主题 fork 一份，然后使用子模块的方式将主题加载自己的博客仓库中，并且在".tarvis.yml"中"hexo clean & hexo g"之前的加入如下指（貌似不加也可以，git 执行 "git clone" 应该是会同时下载子模块的）。

```yml
- git submodule init
- git submodule update
- hexo clean & hexo g
```

### 这个小绿标是不是很诱人，加上去其实很简单：

![little_green](/images/Snipaste_2018-04-07_16-27-48.jpg)

首先让我们再次回到 [Tarvis CI](https://travis-ci.org/)，
点一下这个灰色的按钮（不用管这个的颜色，因为我们的master分支是不进行托管的，所以是灰色的）；

![grey_little](/images/Snipaste_2018-04-07_16-31-58.jpg)

然后在弹出框中选择你进行处理和分支，语言选择Markdown；

![bounce_little](/images/Snipaste_2018-04-07_16-34-56.jpg)

复制最后的地址，将其粘贴到"_travis.sh"文件中生成README.MD的代码处,同时你也可以做一些修改，比如这是我的README.MD：

```sh
cat <<EOF >> README.md
# Milkybird98 唯一指定blog。

Stella Splendida.

[![Build Status](https://travis-ci.org/milkybird98/milkybird98.github.io.svg?branch=hexo)](https://travis-ci.org/milkybird98/milkybird98.github.io)

部署状态 | 集成结果 | 参考值
---|---|---
完成时间 | $time | yyyy-mm-dd hh:mm:ss
部署环境 | $TRAVIS_OS_NAME + $TRAVIS_NODE_VERSION | window \| linux + stable
部署类型 | $TRAVIS_EVENT_TYPE | push \| pull_request \| api \| cron
启用Sudo | $TRAVIS_SUDO | false \| true
仓库地址 | $TRAVIS_REPO_SLUG | owner_name/repo_name
提交分支 | $TRAVIS_COMMIT | hash 16位
提交信息 | $TRAVIS_COMMIT_MESSAGE |
Job ID   | $TRAVIS_JOB_ID |
Job NUM  | $TRAVIS_JOB_NUMBER |
EOF
```

# 结语

感觉根本没啥卵用啊，只不过是从

```sh
hexo clean
hexo g
hexo d
```

变成了

```sh
git add .
git commit -am "xxx"
git push
```

到头来还是三个指令（哭唧唧）。
