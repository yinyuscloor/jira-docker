# JIRA-Docker

> docker 一键部署 JIRA Software 8.15.0 破解版（含高级路线图 Advanced Roadmaps 中文汉化）

------


## 环境要求

![](https://img.shields.io/badge/Platform-Linux%20amd64-brightgreen.svg) ![](https://img.shields.io/badge/Platform-Windows%20x64-brightgreen.svg)


## 目录结构说明

```
jira-docker
├── jira
│   ├── agent .................. [atlassian-agent 破解 agent]
│   ├── plugins-patched ........ [高级路线图插件汉化版 jar（构建时覆盖镜像内插件）]
│   ├── atlassian .............. [jira web 数据（运行时生成，不入库）]
│   └── conf
│       └── server.xml ......... [jira web 配置]
├── pg
│   ├── data ................... [postgresql 数据库文件（运行时生成，不入库）]
│   └── driver ................. [postgresql JDBC 驱动]
├── .gitignore
├── Dockerfile ................. [docker 编排剧本]
├── docker-compose.yml ......... [docker 编排剧本]
└── README.md .................. [此 README 说明]
```

## 部署步骤

- 宿主机安装 docker、docker compose
- 下载仓库： `git clone https://github.com/yinyuscloor/jira-docker.git /usr/local/jira-docker`
- 打开仓库目录： `cd /usr/local/jira-docker`
- 构建镜像并运行： `docker compose up -d`
- 启动后，访问 [`http://localhost:8080`](http://localhost:8080) 打开 JIRA
- 初次运行会跳转到 Setup 界面，选择 `I'll set it up myself`，然后点击 `Next`
- 此时会要求配置数据库，选择 `My Own Database`/`其它数据库 (推荐用于正式生产环境)`，根据 `docker-compose.yml` 的配置填写数据库配置：
  - Database Type:  PostgreSQL
  - Hostname:       postgres
  - Port:           5432
  - Database:       jira
  - Username:       jira
  - Password:       123456
- 点击 `Test Connection`，没有异常则点击 `Next`，等待数据库初始化
- 然后会要求填写应用属性：
  - Application Title:  Anyone JIRA
  - Mode:               Private
  - Base URL:           http://127.0.0.1:8080
- 点击 `Next`，此时会提供 Server ID（形如 `Bxxx-xxxx-xxxx-xxxx`），先复制下来
- 在宿主机执行以下命令生成许可证（把 `<SERVER-ID>` 替换为上一步复制的值）：

```bash
docker compose exec jira java -jar /var/agent/atlassian-agent.jar -d \
  -p jira -m test@test.com -n jira -o http://localhost:8080 -s <SERVER-ID>
```

- 把输出的许可证粘贴到 `Your License Key`，点击 `Next`
- 然后填写 JIRA 管理员信息（Full name / Email / Username / Password 自行填写）
- 点击 `Next`，在 Configure Email Notifications 选择 `later`，点击 `Finish`
- 最后配置语言（中文）、头像等，完成 JIRA 初始化

> 注：`-d` 参数生成的是 Data Center 许可证，可解锁高级路线图（顶部导航「计划」菜单）等 DC 专属功能。
> 如果初始化时已经填了 Server 版许可证，后续想换成 DC 版：管理页面会拒绝粘贴，需要直接改数据库后重启：
>
> ```bash
> docker compose exec postgres psql -U jira -d jira -c \
>   "UPDATE productlicense SET license='<DC许可证>' WHERE id=10000;"
> docker compose restart jira
> ```


## 可选：数据迁移

docker 创建的 JIRA 完全是空的，如果你在其他地方有部署 JIRA，可以把数据迁移到这个项目。

例如已经导出了备份数据 `jira-backup-20210520.zip`，迁移步骤如下：

- 执行命令：`cp jira-backup-20210520.zip jira/atlassian/import`
- 访问 [http://localhost:8080/secure/admin/XmlRestore!default.jspa](http://localhost:8080/secure/admin/XmlRestore!default.jspa)
- 在 File name 填入 `jira-backup-20210520.zip`，然后点击 `Restore`
- 恢复数据完成后重新登陆即可

> 注：数据迁移是全库迁移，所以用户数据、License 数据等都会被覆盖，故前面创建的管理员账号在迁移后已经不存在了。


## 部署到另一台服务器

本项目是自包含的，另一台服务器只需：

1. `git clone` 本仓库
2. `docker compose up -d`
3. 按上文「部署步骤」完成初始化；**许可证需用新机器的 Server ID 重新生成**（命令同上，agent jar 已包含在仓库中）

如需迁移数据，额外拷贝 `pg/data` 和 `jira/atlassian` 两个目录（或按上文用导出备份恢复）。


## 附一：破解原理

使用 [atlassian-agent](https://github.com/hgqapp/atlassian-agent)（v1.3.1，源码在 `jira/agent/atlassian-agent.jar`），通过 `docker-compose.yml` 中的环境变量注入 JVM：

```
JVM_SUPPORT_RECOMMENDED_ARGS=-javaagent:/var/agent/atlassian-agent.jar
```

agent 在运行时 patch 许可证校验逻辑，因此对 Jira 8.x 各版本通用，升级版本无需重新破解。许可证由 agent 自带的 keygen 按 Server ID 生成。


## 附二：高级路线图（Advanced Roadmaps）汉化

官方未提供高级路线图的中文翻译。`jira/plugins-patched/` 中的 3 个 jar 是在官方 8.15.0 插件基础上汉化的版本，覆盖约 1500 条词条（计划页、项目群、团队管理、管理设置、错误提示等主要界面），汉化方式包括：

- 为插件 i18n 资源添加 `*_zh_CN.properties`（服务端渲染部分）
- 将前端编译 JS 中的 `AJS.I18n.getText("key")` 调用直接替换为中文文案（前端页面）
- 将 `atlassian-plugin.xml` 中硬编码的菜单 label 改为中文

构建镜像时覆盖 `WEB-INF/application-installation/jira-software-application/` 中的原始插件，全新部署自动生效。升级 Jira 版本后需基于新版插件重新汉化。
