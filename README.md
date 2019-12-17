# KSync for Ruby/Jruby
## Description
This gem is a simple folder synchroniser between a changing source folder and a
'backup' destination folder (presumed to be unchanged). It uses a list of files hash which is a
hash containing the filepath as the key and file information [FileSize, FileMTime] as value.

In order to compare the source and destination folders:
* It always creates a list of files hash for the source
* It uses an existing list of files hash for the destination or creates one if it does not exist
* It compares the 2 lists of files hash and copies/deletes from destination accordingly.
* It compares files based on size and then on last modification date. It may optionally uses hash calculation (inactive by default because it is slow)

The gem comes with a frontend, 'ksync' which can be used directly to invoke the main class.

## Options
Following options may be used:
```
  -d or --dry_run         : Do a dry run (nothing will be changed) (default : do the real copy)
  -v or --verbosity=value : The level of verbosity (1..3) (default = 0 : very silent)
  -u or --use_hash        : Use hash based calculation of files differences (default : dont use hash)
  -f or --force_dest_hash : Force recalculation of files hash in destination folder (default : use existing files hash).
                            Use this option to still take into account changes done on destination
  -h or --help            : Display help message
```
## Examples
To backup folder c:/dev to c:/dev_backup with default options:

  ksync c:/dev c:/dev_backup

The above, but inside rour ruby code:
```
  require 'ksync'
  KSync::Base.new({:src => 'c:/dev', :dst => 'c:/dev_backup'}).do_sync
```
the method do_sync will return false if there were no changes, true otherwise

To backup folder c:/dev to c:/dev_backup forcing hash calculation (hash calculation will only be used if the files have
the same size and modification date):
```
  ksync --use_hash c:/dev c:/dev_backup
```
or
```
  ksync -u c:/dev c:/dev_backup
```
## Tests
To run the tests from the gem folder:

```
  rake test
```

Notes
If any files in the destination folder have changed then there is no guarantee that the changes will be detected.
This is a fast backup solution and presumes that the destination never changes. However, in order to bypass this
apparent limitation, the option -f or --force_dest_hash may be used. In this case, the destination folder files hash
will be recreated and so will reflect the changes on the destination. The syncing then will take place normally.
