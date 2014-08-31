db-mysql
========

Docker-Image running a MYSQL-Server

Build
-----

```
docker build -t db-mysql .
```

Run
---

```
docker run -d -e MYSQL_PASS="rootpass" --name="db-mysql" db-mysql
```