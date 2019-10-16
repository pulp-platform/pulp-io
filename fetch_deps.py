import yaml
import io
import pprint
import tqdm

import os
import subprocess
from shutil import copyfile
import warnings

default_server = "https://github.com"
default_group  = "pulp-platform"

ips_folder = "ips"
base_folder = os.getcwd()


ips_folder_abs = base_folder + "/" + ips_folder

with open("ips_list.yml", 'r') as stream:
  ips_data = yaml.safe_load(stream)
  subprocess.check_output("mkdir " + ips_folder, shell=True)
  for ip in ips_data.keys():
  	print(ip)
  	composed_url = ""
  	try:
  	    if "server" in ips_data[ip].keys():
  	        composed_url = ips_data[ip]['server']
  	    else:
  	        composed_url = default_server
  	except AttributeError:
  	    print("Using Default server for " + ip + " ip")

  	try:
  	    if "group" in ips_data[ip].keys():
  	        composed_url = composed_url + "/" + ips_data[ip]['group']
  	    else:
  	        composed_url = composed_url + "/" + default_group
  	except AttributeError:
  	    print("Using Default group for " + ip + " ip")

  	composed_url = composed_url + "/" + ip + ".git"

  	os.chdir(ips_folder)
  	cmd = "git clone " + composed_url
  	subprocess.check_output(cmd, shell=True)

  	try:
  	    if "commit" in ips_data[ip].keys():
  	        commit_hash = ips_data[ip]['commit']
  	        os.chdir(ip)
  	        cmd = "git checkout " + commit_hash
  	        subprocess.check_output(cmd, shell=True)
  	    else:
  	        print("No commit provided")
  	except AttributeError:
  	    print("Using most recent commit for " + ip + " ip")

  	os.chdir(base_folder)



    #bash_script.write()