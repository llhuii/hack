#!/usr/bin/python
import base64
import json
import os
import yaml

class Config():
  ca_crt = "__ca.crt"
  client_crt = "__client.crt"
  client_key = "__client.key"

  def __init__(self):
    self.load_config()

  def load_config(self):
    f = os.getenv("KUBECONFIG", "/root/.kube/config")
    content = ''
    with open(f, "r") as f:
      c = 9
      while c:
        c = f.read()
        content += c

    config = None
    for load in yaml.load, json.loads:
      try:
        config = load(content)
        break
      except:
        pass

    if not config:
      raise Exception("can not load %s" % f)
    self.config = config

  def get_filter_by_name(self, key):
    def f(name):
      for c in self.config.get(key, []):
        if c["name"] == name:
          return c
      return {}
    return f

  def get_cluster(self, context_name=None):
    if context_name is None:
      context_name = self.get_current_context()
    return self._get(context_name, "cluster", self.get_filter_by_name("clusters"))

  def get_user(self, context_name=None):
    if context_name is None:
      context_name = self.get_current_context()
    return self._get(context_name, "user", self.get_filter_by_name("users"))

  def _get(self, context_name, key, func):
    return func(self.get_filter_by_name("contexts")(context_name)["context"][key])

  def get_current_context(self):
    return self.config["current-context"]

  def save_crts(self):
    cluster = self.get_cluster()["cluster"]
    ca_content = base64.b64decode(cluster["certificate-authority-data"].encode())
    save(self.ca_crt, ca_content)

    u = self.get_user()["user"]
    crt_content = base64.b64decode(u["client-certificate-data"].encode())
    save(self.client_crt, crt_content)

    key_content = base64.b64decode(u["client-key-data"].encode())
    save(self.client_key, key_content)

  def get_curl_cmds(self):
    curl_cmds = ["curl"]
    self.save_crts()
    curl_cmds.extend(["--cacert", self.ca_crt])
    curl_cmds.extend(["--cert", self.client_crt])
    curl_cmds.extend(["--key", self.client_key])

    cluster = self.get_cluster()["cluster"]
    curl_cmds.append(cluster["server"])
    return curl_cmds
    
      
def save(file_name, content):
  open(file_name, "wb").write(content)

c = Config()
curl_cmds = c.get_curl_cmds()
print(" ".join(curl_cmds))
