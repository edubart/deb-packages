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

## Cloning

If you with to clone this repository to contribute to a new package:

```sh
git clone git@github.com:edubart/debian-ppa.git
```

## Building

Make sure you have Docker and `dpkg` installed in your system, then:

```sh
make packages
```

This will build all Debian packages and make them available in the `ppa` directory.

## Publishing

First make sure to have `ppa` branch cloned by doing:

```sh
git worktree add ppa -b ppa origin/ppa
```

Having a GPG for given email already set in the environment,
you can generate a ppa package index and sign then with:

```sh
make update PPA_SIGN_EMAIL=my@email.com
```

Finally do a git commit and push from `ppa` directory.
