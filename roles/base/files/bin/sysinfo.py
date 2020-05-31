#!/usr/bin/python
#coding:utf8
# -*- coding: utf-8 -*-
import socket
import platform
import os, sys, re
import collections

def usagePercent(use, total):
    try:
        ret = (float(use) / total) * 100
    except ZeroDivisionError:
        raise Exception("ERROR - zero division error")
    return ret

def memInfo():
    try:
        f = open('/proc/meminfo', 'r')
        for line in f:
            if line.startswith('MemTotal:'):
                mem_total = int(line.split()[1])
            elif line.startswith('MemFree:'):
                mem_free = int(line.split()[1])
            elif line.startswith('Buffers:'):
                mem_buffer = int(line.split()[1])
            elif line.startswith('Cached:'):
                mem_cache = int(line.split()[1])
            elif line.startswith('SwapTotal:'):
                vmem_total = int(line.split()[1])
            elif line.startswith('SwapFree:'):
                vmem_free = int(line.split()[1])
            else:
                continue
        f.close()
    except:
        return None
    total_mem = str(mem_total/1024)
    physical_percent = usagePercent(mem_total - (mem_free + mem_buffer + mem_cache), mem_total)
    return total_mem, physical_percent

def cpuInfo():
    corenumber = []
    with open('/proc/cpuinfo') as cpuinfo:
            for i in cpuinfo:
                if i.startswith('processor'):
                    corenumber.append(i)
                if i.startswith('model name'):
                    cpu_mode = i.split(":")[1].strip(' ').strip('\n')
            corenumber = len(corenumber)
    return corenumber, cpu_mode

def ipaddrInfo():
    def add(dic, key, value):
        dic.setdefault(key, []).append(value)
    ipinfo = {}
    for i in os.popen('/sbin/ip a').readlines():
        if re.match(r'\d', i):
            devname = i.split(':')[1].strip(' ')
            continue
        if re.findall(r'ether', i):
            devmac = i.split()[1].strip(' ')
            add(ipinfo, devname, devmac)
            continue
        if re.findall(r'global', i):
            devip = i.split()[1].strip(' ')
            add(ipinfo, devname, devip)
    return ipinfo

if __name__=="__main__":
    hostname = socket.gethostname()
    os_core_version = platform.release()
    total_mem = memInfo()[0]
    used_mem = memInfo()[1]
    cpu_number, cpu_mode= cpuInfo()
    ipaddr = ipaddrInfo()
    print("=======================================")
    print("%-15s\t\t%s\n" % ("主机名:",hostname)),
    print("%-15s\t\t%s\n" % ("系统内核版本:",os_core_version)),
    print("%s:\t\t%s\n"%("CPU生厂商",cpu_mode)),
    print("%s:\t\t%s\n"%("CPU核心数",cpu_number)),
    print("%-15s\t\t%s\n"%("总内存:",total_mem+"M")),
    print("%-15s\t\t%s\n"%("内存使用率:",str(int(used_mem))+"%")),
    for dev, info in ipaddr.items():
        if len(info) >= 2:
            print("网卡:%-10s\t\t%-20s\t%s" %(dev, info[1], info[0]))
