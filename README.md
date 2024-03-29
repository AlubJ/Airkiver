# Airkiver
Game File Archive Tool

## Tested Platforms
I have tested this on Windows, MacOS, and iOS. It has worked quite well on those three platforms.

## Performance Overhead
With smaller archives, the performance is quite good, with the `.retrieve()` method only taking about 0.06ms to execute, but with bigger archives, this number can ramp up. I tested this with an 800MB archive (2.5GB uncompressed) and the `.retrieve()` method took ~300ms to execute. I highly doubt that most GameMaker projects are going to use 2.5GB of external data.

## Airkive.py usage:
`python Airkive.py [outputName]`

The Python script will ignore certain files, you can edit these in the script. The default files to get ignored are;
 - `".DS_Store"`
 - `"Airkiver.py"`
 - `"[outputName].ft"`
 - `"[outputName].fs"`

## GML usage:
### Load File Table
`new Airkiver([filepath], [build_directory_tree])` Load an Airkive file and return an Airkive Struct

Returns: `Struct`

| Argument | Type | Default | Description |
|---|---|---|---|
|`filepath`|`String`|`""`|Filepath of the archive filetable|
|`build_directory_tree`|`Bool`|`true`|Whether to build a directory tree on load|

### Load Method
`.load([filepath])` Load an Airkive file into the struct

Returns: N/A

| Argument | Type | Default | Description |
|---|---|---|---|
|`filepath`|`String`|N/A|Filepath of the archive filetable|

### Build Directory Tree Method
`.build_directory_tree()` Build a directory tree based on the file table

Returns: N/A

### Retrieve Method
`.retrieve(filepath, [validate])` Retrieve an archived file

Returns: `Buffer ID`

| Argument | Type | Default | Description |
|---|---|---|---|
|`filepath`|`String`|N/A|Filepath of the archived file|
|`validate`|`Bool`|`false`|Validate file with CRC32|

### Retrieve Text Method
`.retrieve_text(filepath, [validate])` Retrieve an archived file as a string

Returns: `String`

| Argument | Type | Default | Description |
|---|---|---|---|
|`filepath`|`String`|N/A|Filepath of the archived file|
|`validate`|`Bool`|`false`|Validate file with CRC32|

### Exists Method
`.exists(filepath)` Check if a file exists in the archive

Returns: `Bool`

| Argument | Type | Default | Description |
|---|---|---|---|
|`filepath`|`String`|N/A|Filepath of the archived file|

### Retrieve Names Method
`.retrieve_names()` Retrieve the list of filenames as an array

Returns: `Array<String>`
