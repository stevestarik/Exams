# Quickstart
```bash
chmod +x extract
./extract -h
```
# BASH
Write a bash script called **extract** which can unpack multiple packed files,
and even traverse folders recursively and unpack all archives in them - regardless of the
specific algorithm that was used when packing them. Following is the exact synopsis:
extract [-h] [-r] [-v] file [file...]
Given a list of filenames as input, this script queries each target file (parsing the output of the
file command) for the type of compression used on it. Then the script automatically invokes
the appropriate decompression command, putting files in the same folder. If files with the
same name already exist, they are overwritten.
Unpack should support 4 unpacking options - gunzip, bunzip2, unzip, uncompress.
Adding more options should be VERY simple.
Note that file names and extensions have no meaning - the only way to know what method
to use is through the file command!
If a target file is not compressed, the script takes no other action on that particular file.
If the target is a directory then it decompresses all files in it using same method.
Command echos number of archives decompressed
Command returns number of files it did NOT decompress
Additional switches:
- v - verbose - echo each file decompressed &amp; warn for each file that was NOT
decompressed
- r - recursive - will traverse contents of folders recursively, performing unpack on each.
- h - Should receive a HELP notice