#!/usr/bin/python
from PIL import Image
import sys
from struct import *
import argparse

parser = argparse.ArgumentParser(description='generate include or binary file from picture')
parser.add_argument("filename", help="image file name")
parser.add_argument("output", help="specify bin for a binary file and inc for an include file")
args = parser.parse_args()

im = Image.open(args.filename) # Can be many different formats.
pix = im.load()
name = args.filename.split('.')[0]

if args.output == "inc":
    file_write = open(f"{name}.inc", "w")

    print(f"; size: {im.size}", file=file_write)
    print(f"{name}", end=' ', file=file_write)
    width, heigth = im.size  # Get the width and hight of the image for iterating over
    for y in range (0, heigth):
        for x in range (0, width):
            print(f"dd 0{format(pix[x,y][0], 'x').zfill(2)}{format(pix[x,y][1], 'x').zfill(2)}{format(pix[x,y][2], 'x').zfill(2)}h", file=file_write)

    file_write.close()
elif args.output == "bin":
    file_write = open(f"{name}.bin", "wb")
    width, heigth = im.size  # Get the width and hight of the image for iterating over
    for y in range (0, heigth):
        for x in range (0, width):
            file_write.write(pack('i', (pix[x,y][0] << 16) | (pix[x,y][1] << 8) | pix[x,y][2]))
    file_write.close()
else:
    print(f"No arguments given or unknown: {args.type}")
