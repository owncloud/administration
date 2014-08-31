Usage
=====

Build
-----

```
docker build -t data-vol .
```

Run
---

```
docker run -dv <host-path>:/data-vol --name data-vol data-vol
```