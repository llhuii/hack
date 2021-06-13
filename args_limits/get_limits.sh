#!env -i /bin/bash

get_limit_of_a_key() {
  # always return 128KB in linux
  # same as the limit size of an argument
  a=A
  for((i=1;i<20;i++)) {
    a+=$a
  }
  export b
  for((lo=1<<10,hi=1<<i;mid=lo+(hi-lo)/2, lo<hi;)) {
    b=${a::mid}
    ls &>/dev/null && {
      lo=$[mid+1]
        } || {
      hi=$[mid]
      }
   }

 for((o=lo-1;o<=lo;o++)) {
   echo test size of one env key $[o+3]
   b=${a::o}
   env | wc 2>/dev/null
 }
 # 3 is added, including b= and '\0' 
 max_size_one_arg=$[3+lo-1]
 echo one environment key=value max length $max_size_one_arg
 unset a b
}

get_limit_of_args() {
  local a
  M=$[(128<<10)-1]
  #max_arg=$(tr -dc '[:alnum:]' /dev/urandom|head -c $[M-1])
  a=A
  for((i=1;M>>i;i++)) {
    a+=$a
  }

  function check() {
    local command=/bin/echo
    local size=$[$1-${#command}-1] args=()

    local env_size=$(env|wc -c)
    local env_pointer=$(env|wc -l)
    size=$[size - env_size - env_pointer*8]

    # need to include '\0'
    for((i=size/(${#a}+1);i--;)) {
      args+=($a)
    }
    ((rem=size%${#a})) && args+=("${a::$rem-1}")
    
    $command ${args[@]} &>/dev/null 
  }

  lo=$M
  hi=$[$(getconf ARG_MAX)+1024]

  for((;mid=lo+(hi-lo)/2, lo<hi;)) {
    check $mid && {
      lo=$[mid+1]
        } || {
      hi=$[mid]
      }
   }

   echo the limit size of args+env $[lo-1]

}


get_limit_of_a_key
get_limit_of_args
