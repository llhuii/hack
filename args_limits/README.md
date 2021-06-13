errno of E2BIG:
1. the limit size of args and all environments
2. the limit size of a environment key(i.e. key=value) or an argument(which is a constant 128KB)

https://unix.stackexchange.com/a/120842

https://www.in-ulm.de/~mascheck/various/argmax/

check this [bash script](./get_limits.sh)

in my os(ubuntu 18.04, 4.15.0-128-generic, x86_64), it outputs `$[128<<10]`
