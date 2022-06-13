
Environment variables to deal with operation modes:

- **PARALLELISM=number**

  The maximum number of parallel processes to use when running a task (chmod or chown). This is important to accelerate processing. The default is 4. Minimum is 1, maximum is 10

- **BATCH_SIZE=number**

  The size of each parallel batch to be processed. A batch's contents are processed in order, but when running in parallel multiple batches are run at the same time. The default is 1,000.

- **DEBUG=(True|False)**

  Enable debug mode, which causes additional output to view what the script is thinking/doing (this is False by default)

- **NOROOT=(True|False)**

  Enable non-root mode. This may have an impact on the script's ability to perform its duties as non-root users have limited ability to change file ownership and permissions based on existing ownership and permissions. This is disabled by default (i.e. must run as root)

This is an example document listing jobs. These will be specified via the environment variable **JOBS**. The environment variable may also point to a file containing this type of YAML:

```yaml
jobs:
  - ownership: "ownership information 1"
    permissions: "permissions to set 1"
    flags: [ "flag1.1", "flag1.2", "flag1.3", "flag1.4", ... ]
    targets: [ "/some/dir1", "/another/dir1", ... ]
  - ownership: "ownership information 2"
    permissions: "permissions to set 2"
    flags: [ "flag2.1", "flag2.2", "flag2.3", "flag2.4", ... ]
    targets: [ "/some/dir2", "/another/dir2", ... ]
  - ownership: "ownership information 3"
    permissions: "permissions to set 3"
    flags: [ "flag3.1", "flag3.2", "flag3.3", "flag3.4", ... ]
    targets: [ "/some/dir3", "/another/dir3", ... ]
  # ...
  - ownership: "ownership information N"
    permissions: "permissions to set N"
    flags: [ "flagN.1", "flagN.2", "flagN.3", "flagN.4", ... ]
    targets: [ "/some/dirN", "/another/dirN", ... ]
```

**ownership**

May be a string describing a user:group pair, or the path of a file/object whose ownership is to be mimicked. All components are optional. Here are some examples:

- bob:admins (owner = bob, group = admins)
- :editors (keep user, group = editors)
- bill (owner = bill, keep group)
- jim: (owner = jim, group = jim's default group)
- /some/file/path (copy ownership from the given path, must be an absolute path, and it must exist)

**permissions**

May be a string describing a set of permissions to apply, as accepted by chmod, or the path of a file/object whose permissions are to be mimicked (must be an absolute path, and it must exist).

**flags**

May be a combination of (\* marks flags enabled by default):

- **quiet \***

  no output (***default***)

- **changes**

  only output changes done

- **verbose**

  enable the most verbose output

- **recurse \***

  changes should be applied recursive (***default***)

- **norecurse**

  changes should not be applied recursively

- **forced**

  always perform the changes

- **noforced \***

  only perform the changes when required (***default***)

- **deref \***

  dereference symbolic links (***default***)

- **noderef**

  do not dereference symbolic links

- **create**

  create target directories if missing

- **nocreate \***

  don't create target directories if missing (***default***)

- **traverse**

  traverse any symbolic links to directories encountered

- **notraverse \***

  don't 'traverse any symbolic links to directories encountered (***default***)

**targets**

The files or directories to which the requested actions should be applied.

In the end, the commands to be executed look like this (could be chown or chgrp, depending):

```bash
$ mkdir -p target1 [target2 ... targetN]  # only if the create flag is given
$ find target1 [target2 ... targetN] | xargs -P ${PARALLEL} -n ${BATCH} chown-or-chgrp [flags] <ownership>
$ find target1 [target2 ... targetN] | xargs -P ${PARALLEL} -n ${BATCH} chmod [flags] <mode>
```

These commands would be executed using subprocess.Popen(...).
