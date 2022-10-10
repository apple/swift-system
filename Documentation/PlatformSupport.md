
# Platform Support

Darwin platforms are binary and source stable. Linux platforms follow semantic versioning. Windows follows semantic versioning.

### Windows concerns

Trying to perfectly unify Windows with Darwin and Linux at the API level is ultimately a futile endeavor. However, in some specific cases, Windows does have directly corresponding syscalls or near-equivalents.

Windows-specific details are open to reevaluation pending more Windows expertise for the project.


## API to syscall mapping

### `Errno`

#### Instance computed properties

| API                | Darwin     | Linux      | Windows    |
|:-------------------|:-----------|:-----------|:-----------|
| `description`      | `strerror` | `strerror` | `strerror` |
| `debugDescription` | `strerror` | `strerror` | `strerror` |


### `FileDescriptor`

#### Instance methods

| API                          | Darwin      | Linux       | Windows                                            |
|:-----------------------------|:------------|:------------|:---------------------------------------------------|
| `open`                       | `open`      | `open`      | `_wsopen_s(..., _SH_DENYNO, _S_IREAD | _S_IWRITE)` |
| `close`                      | `close`     | `close`     | `_close`                                           |
| `seek`                       | `lseek`     | `lseek`     | `_lseeki64`                                        |
| `read`                       | `read`      | `read`      | `_read`                                            |
| `read(fromAbsoluteOffset:)`  | `pread`     | `pread`     | *custom*                                           |
| `write`                      | `write`     | `write`     | `_write`                                           |
| `write(fromAbsoluteOffset:)` | `pwrite`    | `pwrite`    | *custom*                                           |
| `duplicate`                  | `dup`       | `dup`       | `_dup`                                             |
| `duplicate(as:)`             | `dup2`      | `dup2`      | `_dup2`                                            |
| `resize`                     | `ftruncate` | `ftruncate` | *N/A*                                              |


#### Static methods

| API    | Darwin | Linux  | Windows |
|:-------|:-------|:-------|:--------|
| `pipe` | `pipe` | `pipe` | *N/A*   |

<details><summary>*Windows notes*</summary>

Windows has custom implementations for reading from or writing to an absolute offset within a file.

File resizing and pipes are not available on Windows at this point.

</details>


## **Types**

**TODO**

## **Values**

**TODO**





