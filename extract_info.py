# -*- coding: utf-8 -*-
# @Author: Alfio Di Mauro
# @Date:   2019-06-18 10:36:05
# @Last Modified by:   Alfio Di Mauro
# @Last Modified time: 2019-10-16 16:08:16
import yaml
import io
import pprint
import tqdm

import os
import subprocess
from shutil import copyfile
import warnings

base_folder = 'udma_subsystem'
synth_folder = 'synth'         ## cockpit directory
directory_to_check = "ips" ## external dependencies

def custom_formatwarning(msg, *args, **kwargs):
    # ignore everything except the message
    return str(msg) + '\n'

warnings.formatwarning = custom_formatwarning

def prepare_for_synth(dictionary,synth_folder,mode='w',):
  print('Generate Analyze script:\n')
  if 'files_synth' in data_loaded[base_folder]['ips']:
    ips_files = data_loaded[base_folder]['ips']['files_synth']
  else:
    warnings.warn("**WARN: file_synth entry not found for ips in src.yml. Analyze script will point to ips behavioral models")
    ips_files = data_loaded[base_folder]['ips']['files']

  if 'files_synth' in data_loaded[base_folder]['rtl']:
    rtl_files = data_loaded[base_folder]['rtl']['files_synth']
  else:
    warnings.warn("**WARN: file_synth entry not found for rtl in src.yml. Analyze script will point to rtl behavioral models")
    rtl_files = data_loaded[base_folder]['rtl']['files']

  svh_files = dictionary[base_folder]['include']['files']

  file_number = len([item for item in ips_files]) + len([item for item in rtl_files]) + len([item for item in svh_files])

  pbar = tqdm.tqdm(total=file_number,position=0)

  sourcecode_folder = synth_folder + '/sourcecode'
  for x in svh_files:
    copyfile(x, sourcecode_folder+'/'+os.path.basename(os.path.normpath(x)))
    with open(synth_folder+'/synopsys/scripts/analyze_rtl.tcl', mode) as fileh:
        #print('Export analyze command for --> ' + sourcecode_folder+'/'+os.path.basename(os.path.normpath(x)))
        file_path = sourcecode_folder+'/'+os.path.basename(os.path.normpath(x))
        fileh.write('analyze -format sverilog ' + os.path.abspath(file_path)+' \n')
    pbar.update(1)

  for x in ips_files:
    copyfile(x, sourcecode_folder+'/'+os.path.basename(os.path.normpath(x)))
    with open(synth_folder+'/synopsys/scripts/analyze_rtl.tcl', 'a') as fileh:
        #print('Export analyze command for --> ' + sourcecode_folder+'/'+os.path.basename(os.path.normpath(x)))
        file_path = sourcecode_folder+'/'+os.path.basename(os.path.normpath(x))
        fileh.write('analyze -format sverilog ' + os.path.abspath(file_path)+' \n')
    pbar.update(1)
        
  #rtl_files = data_loaded[base_folder]['rtl']['files']
  for x in rtl_files:
    copyfile(x, sourcecode_folder+'/'+os.path.basename(os.path.normpath(x)))
    with open(synth_folder+'/synopsys/scripts/analyze_rtl.tcl', 'a') as fileh:
        #print('Export analyze command for --> ' + sourcecode_folder+'/'+os.path.basename(os.path.normpath(x)))
        file_path = sourcecode_folder+'/'+os.path.basename(os.path.normpath(x))
        fileh.write('analyze -format sverilog ' + os.path.abspath(file_path)+' \n')
    pbar.update(1)



############################################################################################################ ips ips_infos


def extract_ip_info(directory):
      #print("Checking version: " + directory)
      cmd = "git log -n 1 | grep commit"
      cmd_short_hash = "git log --pretty=format:'%H' -n 1"
      commit = subprocess.check_output(cmd_short_hash, shell=True)
      cmd = "git remote show origin | grep Fetch"
      server = subprocess.check_output(cmd, shell=True)
      #print(server.split()[-1].decode('utf8'))
      cmd = "git remote show origin | grep branch"
      branch = subprocess.check_output(cmd, shell=True)
      #print(branch.split()[2].decode('utf8'))
      ips_infos[os.path.basename(os.path.normpath(directory))] = { #'local_path': directory,
      															  'commit': commit.decode('utf8'),
      															  'server': server.split()[-1].decode('utf8'),
      															  'branch': branch.split()[2].decode('utf8'),
      															  }
      ips_list[os.path.basename(os.path.normpath(directory))] = {
                                      'commit': commit.decode('utf8'),
                                      'server': server.split()[-1].decode('utf8'),
                                      }
      with open("src_files.yml", 'r') as stream:
          data_loaded = yaml.safe_load(stream)
          ######---------------------------------------------------------------------|this must be selected from a yml file       |
          for x in data_loaded.keys():
            if 'fpga' not in x:
              ips_rtl_files[x] = data_loaded[x]
              ips_rtl_files[x]['abs_path'] = os.path.normpath(directory)
          
            

          

def walklevel(some_dir, level=1):
    some_dir = some_dir.rstrip(os.path.sep)
    assert os.path.isdir(some_dir)
    num_sep = some_dir.count(os.path.sep)
    for root, dirs, files in os.walk(some_dir):
        yield root, dirs, files
        num_sep_this = root.count(os.path.sep)
        if num_sep + level <= num_sep_this:
            del dirs[:]     

cwd = os.getcwd()

############################################################# extracts information on the ips dependencies and put it in ips_infos
ips_infos = {}
ips_list = {}
ips_rtl_files = {}


print("Generating src file list: \n")
# Get all the subdirectories of directory_to_check recursively and store them in a list:
directories = [os.path.abspath(x[0]) for x in walklevel(directory_to_check,level=1)]
directories.remove(os.path.abspath(directory_to_check)) # If you don't want your main directory included
pbar = tqdm.tqdm(total=len(directories),position=0,leave=True)
for i in directories:
      os.chdir(i)         # Change working Directory
      extract_ip_info(i)  # Run your function
      pbar.update(1)

## enable this part to take a screenshot
#with io.open('../../ips_version_freeze.yml', 'w', encoding='utf8') as outfile:
#    yaml.dump(ips_infos, outfile, default_flow_style=False, allow_unicode=True)
#with io.open('../../ips_list.yml', 'w', encoding='utf8') as outfile:
#    yaml.dump(ips_list, outfile, default_flow_style=False, allow_unicode=True)    
#print("IPs versions saved to ips_version_freeze.yml file")

#print(ips_rtl_files)

os.chdir(cwd)

with io.open('files.yml', 'w', encoding='utf8') as outfile:
  with open("src.yml", 'r') as stream:
      data_loaded = yaml.safe_load(stream)
      data_loaded[base_folder]['ips'] = ips_rtl_files
  yaml.dump(data_loaded, outfile, default_flow_style=False, allow_unicode=True)



############################################################### read the src.yml file and parse it

# Read YAML file
with open("files.yml", 'r') as stream:
    data_loaded = yaml.safe_load(stream)

############################################################### depending on the src.yml file (auto-generated or not), generate the compilation and analyze script

rtl_files = data_loaded[base_folder]['rtl']['files']
#print('Extract design files:')
with open('sim/rtl_file_list.txt', 'w') as fileh:
	for x in rtl_files:
		#print('Reading --> ' + os.path.abspath(x))
		fileh.write(os.path.abspath(x)+' \n')

svh_files = data_loaded[base_folder]['include']['files']
#print('Extract header files:')
with open('sim/svh_file_list.txt', 'w') as fileh:
	if svh_files != None:
		for x in svh_files:
			#print('Reading --> ' + os.path.abspath(x))
			fileh.write(os.path.abspath(x)+' \n')

ips_files = data_loaded[base_folder]['ips']
#print('Extract dependencies:')
with open('sim/ips_file_list.txt', 'w') as fileh:
  for key in ips_files.keys():
    file_list = ips_files[key]['files']
    if file_list != None:
      for x in file_list:
        #print('Reading --> ' + os.path.abspath(x))
        fileh.write(ips_files[key]['abs_path'] + "/" + x +' \n')

########################################################

warnings.simplefilter("always")
#prepare_for_synth(data_loaded,'synth')
#print('Analyze script created in:'+' synth/synopsys/scripts/\n')

