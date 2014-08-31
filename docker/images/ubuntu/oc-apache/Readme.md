Usage
=====

Build
-----

```
docker build -t oc-apache .
```

Run
---

```
docker run -dv <host-path>:/data-vol --name data-vol data-vol 
docker run -d -e MYSQL_PASS="rootpass" --name="db-mysql" db-mysql
docker run -dp 80:80 --link=db-mysql:db --volumes-from data-vol oc-apache
```