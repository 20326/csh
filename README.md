# csh
Cloud shell

## golang.sh

Install a simple [golang](https://golang.org/dl/) environment

```
bash <(curl -fsSL git.io/csh-golang.sh)

bash <(curl -fsSL git.io/csh-golang.sh) -v 1.15.1

curl -fsSL git.io/csh-golang.sh > csh-golang.sh && chmod +x csh-golang.sh && ./csh-golang.sh
```

## lego.sh

Install a simple [lego](https://github.com/go-acme/lego) environment

```
bash <(curl -fsSL git.io/csh-lego.sh)

curl -fsSL git.io/csh-lego.sh | bash

curl -fsSL git.io/csh-lego.sh > csh-lego.sh && chmod +x csh-lego.sh && ./csh-lego.sh

# new
DNSPOD_API_KEY=xxxxxx lego --email=myemail@example.com --dns=dnspod --domains=.example.org --key-type=rsa4096 --accept-tos --pem run
# renew
lego --email="foo@bar.com" --domains="example.com" --http renew --days 15
# renew hook
lego --email="foo@bar.com" --domains="example.com" --http renew --renew-hook="./myscript.sh"
# crontab
30 0 * * * lego --email="foo@bar.com" --domains="example.com" --http renew --days 15 > /dev/null
```
## buildctrl.sh
Build control.sh & bin.service file
```
cd YourBinDir
bash <(curl -fsSL git.io/csh-buildctrl.sh) -b binfile

# using
./control.sh start |stop | status | restart

```

## speedtest.sh

Install a simple [speedtest-go](https://github.com/librespeed/speedtest-go) environment

```
bash <(curl -fsSL git.io/csh-speedtest.sh)

curl -fsSL git.io/csh-speedtest.sh | bash

curl -fsSL git.io/csh-speedtest.sh > csh-speedtest.sh && chmod +x csh-speedtest.sh && ./csh-speedtest.sh

# build control.sh
cd /opt/speedtest
bash <(curl -fsSL git.io/csh-buildctrl.sh) -b speedtest-backend

```
## Lisence

[MIT](https://github.com/20326/csh/blob/master/LICENSE) © brian
