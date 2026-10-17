#!/usr/bin/env python3
"""Shorten .bit design metadata for legacy U-Boot; preserve payload exactly."""
import argparse,struct,hashlib
from pathlib import Path

def parse(b):
 i=2+struct.unpack_from('>H',b,0)[0]
 assert b[i:i+2]==b'\x00\x01';i+=2
 fields=[]
 for key in b'abcd':
  assert b[i]==key;i+=1
  n=struct.unpack_from('>H',b,i)[0];i+=2
  fields.append(b[i:i+n]);i+=n
 assert b[i]==ord('e');i+=1
 n=struct.unpack_from('>I',b,i)[0];i+=4
 assert len(b)-i==n
 return fields,b[i:]
p=argparse.ArgumentParser();p.add_argument('input');p.add_argument('output');a=p.parse_args()
b=Path(a.input).read_bytes();fields,payload=parse(b)
n=2+struct.unpack_from('>H',b,0)[0]+2
out=b[:n]
fields[0]=fields[0].split(b';SW_CRC=')[0].split(b';SW_HDR_SHA256=')[0].rstrip(b'\0')+b'\0'
assert len(fields[0])<80
for key,value in zip(b'abcd',fields):out+=bytes([key])+struct.pack('>H',len(value))+value
out+=b'e'+struct.pack('>I',len(payload))+payload
assert parse(out)[1]==payload
Path(a.output).write_bytes(out)
print('Payload unchanged:',hashlib.sha256(payload).hexdigest())
print('Output SHA256:',hashlib.sha256(out).hexdigest())
