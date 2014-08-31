docker-owncloud
===============

Docker container for ownCloud on nginx: http://owncloud.com

Build
-----

```
docker build -t oc-nginx .
```

Run
---

```
docker run -dv <host-path>:/data-vol --name data-vol data-vol
docker run -d -e MYSQL_PASS="rootpass" --name="db-mysql" db-mysql
docker run -dp 80:8000/tcp --link=db-mysql:db --volumes-from data-vol -v "/etc/localtime":"/etc/localtime":ro oc-nginx
```