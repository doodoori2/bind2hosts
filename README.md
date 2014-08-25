bind2hosts
========


# Usage
```bash
$./bind2host.sh
Usage:  bind2host.sh [FILE]...
        bind2host.sh convert bind9 db file to hosts file

Examples:
        bind2host.sh db.local
				bind2host.sh db.*
```

#Example

## db.local
```bash
$ cat samples/db.local
;
; BIND data file for local loopback interface
;
$TTL  604800
@ IN  SOA localhost. root.localhost. (
            2   ; Serial
       604800   ; Refresh
        86400   ; Retry
      2419200   ; Expire
       604800 ) ; Negative Cache TTL
;
@ IN  NS  localhost.
@ IN  A 127.0.0.1
@ IN  AAAA  ::1

$ ./bind2host.sh samples/db.local
###### bind2hosts.sh samples/db.local LOCALHOST
127.0.0.1 @.localhost           # @ IN  A 127.0.0.1
###### bind2hosts.sh samples/db.local LOCALHOST
```

## db.cnames
```bash
$ cat samples/db.cnames
;
; BIND data file for local loopback interface
;
$TTL  604800
@ IN  SOA localhost. root.localhost. (
            2   ; Serial
       604800   ; Refresh
        86400   ; Retry
      2419200   ; Expire
       604800 ) ; Negative Cache TTL
;
@ IN  NS  localhost.
@ IN  A 127.0.0.1
@ IN  AAAA  ::1

SUB1 IN A 10.0.0.1
SUB2 IN A 10.0.0.2
SUB3 IN A 10.0.0.3
SUB4 IN A 10.0.0.4

CNAME1 IN CNAME SUB1
CNAME2 IN CNAME SUB2
CNAME3 IN CNAME SUB3
CNAME4 IN CNAME SUB4

ROOT_NAMESERVER_A IN CNAME A.ROOT-SERVERS.NET.
ROOT_NAMESERVER_B IN CNAME B.ROOT-SERVERS.NET.
ROOT_NAMESERVER_C IN CNAME C.ROOT-SERVERS.NET.
ROOT_NAMESERVER_D IN CNAME D.ROOT-SERVERS.NET.

$ ./bind2host.sh samples/db.cnames
###### bind2hosts.sh samples/db.cnames LOCALHOST
127.0.0.1 @.localhost           # @ IN  A 127.0.0.1
10.0.0.1 sub1.localhost         # SUB1 IN A 10.0.0.1
10.0.0.2 sub2.localhost         # SUB2 IN A 10.0.0.2
10.0.0.3 sub3.localhost         # SUB3 IN A 10.0.0.3
10.0.0.4 sub4.localhost         # SUB4 IN A 10.0.0.4
10.0.0.1 cname1.localhost               # CNAME1 IN CNAME SUB1
10.0.0.2 cname2.localhost               # CNAME2 IN CNAME SUB2
10.0.0.3 cname3.localhost               # CNAME3 IN CNAME SUB3
10.0.0.4 cname4.localhost               # CNAME4 IN CNAME SUB4
198.41.0.4 root_nameserver_a.localhost          # ROOT_NAMESERVER_A IN CNAME A.ROOT-SERVERS.NET.
192.228.79.201 root_nameserver_b.localhost              # ROOT_NAMESERVER_B IN CNAME B.ROOT-SERVERS.NET.
192.33.4.12 root_nameserver_c.localhost         # ROOT_NAMESERVER_C IN CNAME C.ROOT-SERVERS.NET.
199.7.91.13 root_nameserver_d.localhost         # ROOT_NAMESERVER_D IN CNAME D.ROOT-SERVERS.NET.
###### bind2hosts.sh samples/db.cnames LOCALHOST
```
