/**
 * Created by jfd on 02.07.15.
 */

window.addEventListener('load', function () {
    var submit = document.getElementById('submit');
    submit.removeAttribute('disabled');
    submit.addEventListener('click', function (event) {
        event.preventDefault();

        var username = document.getElementById('user').value;
        var password = document.getElementById('password').value;

        // do whatever you want to determine the hostname / url / login

        var parts = username.split('@');

        username = parts[0];
        var host = parts[1];

        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'http://'+host+'/remote.php/webdav/');
        xhr.withCredentials = true;
        var auth = "Basic " + window.btoa(username + ":" + password);
        xhr.setRequestHeader('Authorization', auth);

        // Response handlers.
        xhr.onload = function() {
            document.location = 'http://'+host+'/';
        };

        xhr.onerror = function() {
            alert('Could not log you in at '+host);
        };

        xhr.send();
        return false;
    })
});
