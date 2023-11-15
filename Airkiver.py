# MIT License
# 
# Copyright (c) 2023 Alun Jones
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Import Libs
import zlib, os, sys
from struct import pack

# Create Memory Buffers
filetable_bytes = bytearray()
archive_bytes = bytearray()

# File Array
allfiles = []

# Begin Writing File System and File Table
filetable_bytes.extend(bytearray("Airkive\0",'utf-8'))    # header
archive_bytes.extend(bytearray("Airkive\0",'utf-8'))    # header

# Write FT Version
filetable_bytes.extend(pack('f', 1.1))

# Output Filename
outFilename = os.path.splitext(sys.argv[1])[0]

# Ignore Files
ignore_files = [".DS_Store", outFilename + ".ft", outFilename + ".fs"]

# Options
compressionType = 1
encryptionKey = ""

# Get Compression Type (Default is "Smart Compression")
if len(sys.argv) >= 3:
    if sys.argv[2] == "--noCompression":
        compressionType = 0
    elif sys.argv[2] == "--smartCompression":
        compressionType = 1
    elif sys.argv[2] == "--forceCompression":
        compressionType = 2
    #else:
        #encryptionKey = sys.argv[2]
        #encryptCRC = zlib.crc32(bytearray(encryptionKey,'utf-8'))

# File Start Offset (Starts at the length of archive_bytes)
offset = len(archive_bytes)

# Start Directory Walk in "\datafiles"
walk_dir = os.getcwd() + "/datafiles"
print(walk_dir)
for root, subdirs, files in os.walk(walk_dir):
    if root[-1] != "/":
        root = root + "/"
    folderpath = root.replace(walk_dir + "/", "")

    print('- directory "%s"' % (folderpath))
    #for subdir in subdirs:
        #print('\t- subdirectory ' + subdir)

    for filename in files:
        file_path = os.path.join(folderpath, filename)
        print('\t- file "%s" (full path: "%s")' % (filename, file_path))
        if (filename not in ignore_files):
            allfiles.append(walk_dir + "/" + file_path)

# Begin Packing Files
print("Packing:")

# Write File Count
filetable_bytes.extend(pack('i', len(allfiles)))

for file in allfiles:
    # Open Source File
    f = open(file, "rb")

    # Make Absolute Paths Relative
    filename = file.replace(walk_dir + "/", "")

    # Debug Print
    print('\t- packing file "%s" (full path: "%s")' % (filename, file))

    # Get Source File Contents
    content = f.read()

    # Write Offset and Uncompressed Size in FT
    filetable_bytes.extend(pack('i', offset))
    filetable_bytes.extend(pack('i', len(content)))

    # Grab the CRC32 of the Source File
    crc32 = zlib.crc32(content)

    # Compress the File Using ZLIB (GameMaker use Compression Level 6)
    if compressionType == 2 or (compressionType == 1 and len(content) > 0x200):
        content = zlib.compress(content, 6)

    # Write Compressed Size, CRC32, Target Archive, Filename and Content to Respective Files
    filetable_bytes.extend(pack('i', len(content)))
    filetable_bytes.extend(pack('I', crc32))
    filetable_bytes.extend(bytearray(outFilename+".fs\0",'utf-8'))
    filetable_bytes.extend(bytearray(filename+"\0",'utf-8'))
    archive_bytes.extend(content)

    # Increase Offset
    offset += len(content)

# Save Files
with open("datafiles/" + outFilename + ".ft", "wb") as file:
        file.write(filetable_bytes)
with open("datafiles/" + outFilename + ".fs", "wb") as file:
        file.write(archive_bytes)
