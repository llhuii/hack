#!/bin/bash
# parse specified namespace specified service account secret token
# simply:
# source this script and run get_token_jwt

function urlbase64_decode() {
  local suffix====
  local in=$1
  echo "$in" | {
    tr -- -_ +/
    # complement trailing =
    echo ${suffix::(4-${#in}%4)%4}
  } | base64 -d
}

function parse_jwt() {
  local token=${1:-$(cat -)}
  local head=$(cut -d. -f1 <<<$token)
  local payload=$(cut -d. -f2 <<<$token)
  local sig=$(cut -d. -f3 <<<$token)

  echo
  echo head: $(urlbase64_decode $head)
  echo 
  echo payload: $(urlbase64_decode $payload)
}

function get_secret_token() {
  # <namespace> <secret_name>
  local namespace=${1}
  local name=${2}
  kubectl get -n $namespace secret $name -o template='{{.data.token}}' | base64 -d
}

function get_token_jwt() {
  local namespace=${1:-default}
  local name=${2-$(kubectl get sa default -o template='{{ range .secrets }}{{.name}}{{end}}')}
  get_secret_token $namespace $name | parse_jwt
}


