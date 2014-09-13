# Full nginx image for ownCloud

## Build

```
docker build -t owncloud-nginx-full .
```

## Run

```
docker run owncloud-nginx-full -p 80:80 -p 443:443
```

## Volume

This image mounts a volume at ```/data```, it requires the
following directories:

* ```/data/ssl``` Within this folder we store the SSL certs
* ```/data/htdocs``` Within this folder you find the webroot
* ```/data/mysql``` Within this folder mysql stores databases
