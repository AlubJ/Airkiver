import zlib, os, sys
from PIL import Image
import numpy as np
from struct import pack
import json
import math

filetable_bytes = bytearray()
archive_bytes = bytearray()

allfiles = []



filetable_bytes.extend(bytearray("Airkive\0",'utf-8'))    # header
archive_bytes.extend(bytearray("Airkive\0",'utf-8'))    # header
filetable_bytes.extend(pack('f', 1.1))

filen = os.path.splitext(sys.argv[1])[0]

compressionType = 1
encryptionKey = ""

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

walk_dir = os.getcwd() + "\\airkive"

offset = 8

for root, subdirs, files in os.walk(walk_dir):
    if root[-1] != "\\":
        root = root + "\\"
    folderpath = root.replace(walk_dir + "\\", "")
    print('- directory "%s"' % (folderpath))

    #for subdir in subdirs:
        #print('\t- subdirectory ' + subdir)

    for filename in files:
        file_path = os.path.join(folderpath, filename)

        print('\t- file "%s" (full path: "%s")' % (filename, file_path))

        allfiles.append(walk_dir + "\\" + file_path)


print("Packing:")
filetable_bytes.extend(pack('i', len(allfiles)))
for file in allfiles:
    f = open(file, "rb")
    filename = file.replace(walk_dir + "\\", "")
    print('\t- packing file "%s" (full path: "%s")' % (filename, file))
    content = f.read()
    filetable_bytes.extend(pack('i', offset))
    filetable_bytes.extend(pack('i', len(content)))
    crc32 = zlib.crc32(content)
    if compressionType == 2 or (compressionType == 1 and len(content) > 0x200):
        content = zlib.compress(content, 5)
    filetable_bytes.extend(pack('i', len(content)))
    filetable_bytes.extend(pack('I', crc32))
    filetable_bytes.extend(bytearray(filen+".fs\0",'utf-8'))
    filetable_bytes.extend(bytearray(filename+"\0",'utf-8'))
    archive_bytes.extend(content)
    offset += len(content)

with open(filen + ".ft", "wb") as file:
        file.write(filetable_bytes)
        
with open(filen + ".fs", "wb") as file:
        file.write(archive_bytes)