# mitm
A script to setup and start a man in the middle proxy with openssl

### Clone repo
```
git clone <repo>
```
### go into local dir
```
cd mitm
```

### setup (generate and self sign keys)
```
bash -x ./mitm.sh listen_port dst_ip:dst_port setup
```

### start mitm proxy
```
bash -x ./mitm.sh 1636 172.20.116.200:636 start
```

### check certificates presented by mitm proxy
```
openssl s_client -CAfile server.crt -verify 5 -showcerts -connect localhost:$listen_port
```

### stop mitm proxy
```
bash -x ./mitm.sh 1636 172.20.116.200:636 stop
```
