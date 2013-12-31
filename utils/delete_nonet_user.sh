#!/bin/bash

su
useradd nonet
passwd nonet

iptables -A OUTPUT -m owner --uid-owner nonet -j DROP

