# Debian PPA

Here is a quick example on how to use the PPA:

```
apt-get update
apt-get install -y curl gpg
curl -fsSL https://edubart.github.io/debian-ppa/KEY.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/cartesi-archive-keyring.gpg] https://edubart.github.io/debian-ppa ./" | tee /etc/apt/sources.list.d/cartesi-archive-keyring.list
apt-get update
apt-get install -y cartesi-machine
cartesi-machine
```

## Building

Make sure you have Docker and `dpkg` installed in your system, then:

```
make
```

This will build all Debian packages and make them available in the current directory.
