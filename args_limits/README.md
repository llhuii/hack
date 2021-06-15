## errno E2BIG, Argument list too long
There are two main cases leading to E2BIG:
1. the limit size of args and all environments: $(getconf ARG_MAX) = 2097152 = 2MB
2. the limit size of an environment key(i.e. key=value) or an argument: 32 Pages, i.e. 128KB

See discussion https://unix.stackexchange.com/a/120842, good ref https://www.in-ulm.de/~mascheck/various/argmax/.

Also check the [my bash script](./get_limits.sh):

In my os(ubuntu 18.04, 4.15.0-128-generic, x86_64), it outputs:
1. the limit of sum of env and args: 2093258 bytes, a little bit smaller than 2MB
2. the limit of an environment key or an argument: 131072, i.e. 128KB
3. getconf ARG_MAX: 2097152, i.e. 2MB
