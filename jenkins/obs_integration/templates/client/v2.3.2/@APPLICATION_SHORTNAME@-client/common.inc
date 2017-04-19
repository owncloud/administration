%if "%{name}" == "owncloud-client"
%define is_owncloud_client 1
%else
%define is_owncloud_client 0
%endif

## Caution: do not change the names of the following three defines.
## prerelease, base_version, tar_version are the interface into buildpackage.pl
## used in rotor.o.c job owncloud-client-linux
## define prerelease as %nil, if this is not a prerelease.
%define prerelease %nil
%define base_version 2.3.1
%define tar_version %{base_version}%{prerelease}


Patch23: packaging.diff
%define _oc_client_apply_common_patches  %patch23 -p1
