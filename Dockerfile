FROM atlassian/jira-software:8.15.0

# 注入 postgres 驱动包
COPY ./pg/driver/postgresql-42.5.0.jar /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/postgresql-42.5.0.jar

# 覆盖高级路线图（Advanced Roadmaps）插件为汉化版（含 zh_CN 词条 + 中文菜单 label）
COPY ./jira/plugins-patched/ /opt/atlassian/jira/atlassian-jira/WEB-INF/application-installation/jira-software-application/
