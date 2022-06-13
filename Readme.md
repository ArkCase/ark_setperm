# ArkCase Permissions Modification Tool

This container provides an easy mechanism to apply permissions and ownership modification to volumes and filesystems. Specifically, it can be used when containers require the contents of their data volumes to be readable or writable by a specific user or group, or to have a specific set of permissions. The tool is intended to support high performance via leveraging parallelism, and it's also somewhat smart about avoiding unnecessary work (see the ***forced*** and ***noforced*** flags, below).

The tool's activities are primarily controlled via environment variables, with a YAML document describing the work to be performed.

## Environment Variables

These are the environment variables that can modify the tool's operations:

- **DRY__RUN=(True|False)**

  Enable dry run mode, which both enables DEBUG mode, and disables executing any actual work on the targets. Intermediate, temporary files will be created, and target files will be inspected, but no changes will be applied.

- **DEBUG=(True|False)**

  Enable debug mode, which causes additional output to view what the script is thinking/doing (this is False by default)

- **PARALLELISM=number**

  The maximum number of parallel processes to use when running a task (chmod or chown). This is important to accelerate processing. The default is 4. Minimum is 1, maximum is 10

- **BATCH_SIZE=number**

  The size of each parallel batch to be processed. A batch's contents are processed in order, but when running in parallel multiple batches are run at the same time. The default is 1,000.

- **NOROOT=(True|False)**

  Enable non-root mode. This may have an impact on the script's ability to perform its duties as non-root users have limited ability to change file ownership and permissions based on existing ownership and permissions. This is disabled by default (i.e. must run as root)

- **JOBS=(YAML|*file-path*)**

  The **JOBS** variable can contain an entire YAML document, a filesystem path, or a URL to one which will be read and used to guid processing. This listing shows an example document:

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

## Document Elements

The document must start with a root array object called ***jobs***, which will contain all the work that needs to be performed. By splitting work into separate instances, a single invocation of the tool can be used to apply many different permissions modifications.

In order for a *job* to perform any work, it must have at least one of ***ownership*** or ***permissions***, and at least one ***target***. Depending on the flags (specifically, ***forced*** and ***noforced***, below) the tool may select to skip the work anyway, but if there are no *targets*, or no *permissions* or *ownership* changes, then the job will be skipped since no work is being requested.

Each *job* may contain the following elements:

### **ownership**

May be a string describing a user:group pair, or the path of a file/object whose ownership is to be mimicked. All components are optional. Here are some examples:

- **bob:admins** (owner = bob, group = admins)
- **:editors** (keep user, group = editors)
- **bill** (owner = bill, keep group)
- **jim:** (owner = jim, group = *jim's default group*)
- **/some/file/path** (copy ownership from the given path, must be an absolute path, and it must exist - both owner and group will be copied over)

Alternatively, it can be specified using a map which contains either a combination of user/group members, or the reference member:

```yaml
ownership:
  owner: "the owner"
  group: "the group (or use * to select the owner's default group)"
  reference: "/the/file/to/be/referenced/for/ownership"
```

### **permissions**

May be a string describing a set of permissions to apply, as accepted by **chmod**, or the path of a file/object whose permissions are to be mimicked (must be an absolute path, and it must exist). The exact same syntax that **chmod** supports is accepted, and validated.

### **flags**

This element contains flags that will affect how the commands will do their job. It's expected to be an array of strings, but may also be a comma-separated string containing any of the following values (\* marks flags enabled by default):

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

  don't traverse any symbolic links to directories encountered (***default***)

Please note that the **quiet**, **changes**, and **verbose** are mutually exclusive and only one may be used at any given time. The same goes for flags that have a "*no*" variant - i.e. **traverse** and **notraverse** may not be used at the same time.

### **targets**

This array contains the files or directories to which the requested actions should be applied. All paths may be absolute, and depending on the use of **create** or **nocreate**, they may have to exist beforehand. Note that when using **create**, only directories will be created.

## Executed commands

The commands to be executed take a form similar to the following:

```bash
$ mkdir -p target1 [target2 ... targetN]  # only if the create flag is given
$ find target1 [target2 ... targetN] | xargs -P ${PARALLEL} -n ${BATCH} chown-or-chgrp [flags] <ownership>
$ find target1 [target2 ... targetN] | xargs -P ${PARALLEL} -n ${BATCH} chmod [flags] <mode>
```
Depending on circumstances, the ownership command may be *chown* or *chgrp* - i.e. if only group changes are requested, *chgrp* is the appropriate tool to use.

These commands would be executed using subprocess.Popen(...), so that paths with spaces or strange characters can be processed adequately.
