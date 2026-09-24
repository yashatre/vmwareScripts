# File size scanner for Windows

`filesizes.c` scans a drive or folder recursively and displays the five largest
and five smallest regular files. It scans once and retains at most ten file
paths, rather than storing and sorting every file on the drive. Files are ranked
by their logical size in bytes. Equal-size files retain their discovery order.

## Build

From a Visual Studio Developer Command Prompt:

```cmd
cl /W4 /O2 /std:c11 filesizes.c /Fe:filesizes.exe
```

Or with MinGW-w64 GCC:

```cmd
gcc -std=c11 -O2 -Wall -Wextra -municode filesizes.c -o filesizes.exe
```

## Run

```cmd
filesizes.exe C:\
filesizes.exe "D:\My Folder"
```

The program does not modify any files. It skips reparse points (including
symbolic links and junctions) to avoid scanning the same location repeatedly.
It counts folders it cannot read and reports other enumeration errors. Missing
files under inaccessible folders cannot appear in the rankings. A nonzero exit
code indicates an incomplete scan or invalid input. Console output supports
Unicode paths in a normal modern Windows terminal.
