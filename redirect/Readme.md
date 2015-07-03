# TODO
Trying to login the user by sending basic auth credentials to the webdav endpoint requires setting
```php
header("Access-Control-Allow-Origin: https://<hostname>");
header("Access-Control-Allow-Credentials: true");
```

even then chrome and firefox send an OPTION request to the server which with the current codebase returns a 401, causing the whole attempt to fail.

Instead of monkey patching the webdav endpoint to create a session which has Lukas screaming anyway we should properly set headers for the normal login and then fetch the login page, extract the requesttoken and finally do the login by sending the normal form data with username, password and the requesttoken.

