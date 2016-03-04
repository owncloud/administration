## Octo-Weasel - automated performance measuring

Create a file called `hosts` and put the address of the server in there:

```
[performance]
1.2.3.4
```

Provisioning of the server:

```
$ ansible-playbook playbook.yml -i hosts
```

Run the tests (`ab01de` is the commits sha sum that should be tested):

```
ssh 1.2.3.4
/root/run-performance-test.sh ab01de
```

Test results can be found in `/tmp/performance-tests` and have the time stamp of the start in it's name.

Place a file `/root/api` with the API URL and credentials to automatically upload the results:

```
export API_URL='https://api.example.org/'
export API_TOKEN='abcdefghi123456789'
```
