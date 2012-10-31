ksync
=====

This class does a sync between source and destination folders 

The comparison is based on : 

  a) size & date by default and optionally on 
  b) sha1 hash of the source and destination files

NOTE: If any files in the destination folder have changed and the -u option (use hash) is not 
specified, then these changes will NOT be detected. This is a fast backup solution and presumes
that the destination never changes.
This algo has been tested with 

TODO: change the Find.find + hash based mechanism into a more robust one not limited by hash size and 
consequently memory size

Usage: ksync.rb [options] source_folder destination_folder

    -d, --dry_run                    dry run (default : do the real copy - no dry run)
    -v, --verbosity=value            The level of verbosity (1..3) (default = 0 : very silent)
    -u, --use_hash                   use hash calculation (default : dont use hash)
    -h, --help


How to config your git to check out this project

if you are behind an authenticating proxy:
    
$ git config --global http.proxy http://proxyuser:proxypwd@proxy.server.com:8080
$ git config --system http.sslcainfo /bin/curl-ca-bundle.crt
$ git remote add origin https://mygithubuser:mygithubpwd@github.com/repoUser/repoName.git

to Clone:

$ git clone https://github.com/kirkytullins/ksync.git
