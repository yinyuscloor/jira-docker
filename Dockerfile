FROM atlassian/jira-software:8.15.0

# 注入 postgres 驱动包
COPY ./pg/driver/postgresql-42.5.0.jar /opt/atlassian/jira/atlassian-jira/WEB-INF/lib/postgresql-42.5.0.jar
