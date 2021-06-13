errno E2BIG, Argument list too long
discussion see https://unix.stackexchange.com/a/120842
good ref: https://www.in-ulm.de/~mascheck/various/argmax/
1. the limit size of args and all environments
   ```bash
   limit=$[$(getconf ARG_MAX) - $(env|wc -c) - $(env|wc -l) * 4 - 2048]
   ```
2. the limit size of a environment key(i.e. key=value) or an argument, a constant value(128KB)


Also check the [my bash script](./get_limits.sh):

In my os(ubuntu 18.04, 4.15.0-128-generic, x86_64), it outputs:
1. 2093258: the limit of sum of env and args
2. 131072, i.e. 128KB: the 
3. 2097152=`$(getconf ARG_MAX)`

