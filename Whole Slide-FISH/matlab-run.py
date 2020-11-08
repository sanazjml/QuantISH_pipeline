#!/usr/bin/env python

import collections
import os.path
import re

def mat_str(str):
  return "'{}'".format(str.replace("'", "''"))

if __name__ == '__main__':
	import sys

	# print usage
	def usage():
		sys.stderr.write('Usage: {} script.m [var=value [...]]'.format(
			sys.argv[0]) + '\n')
		sys.exit(1)

	# parse arguments
	args = sys.argv[1:]
	if len(args) < 1:
		usage()
	script, rest = args[0], args[1:]

	# figure out the script directory
	script_dir, script_base = os.path.dirname(script), os.path.basename(script)
	script_name, _ = os.path.splitext(script_base)

	# parse parameters
	vars = collections.OrderedDict()
	for item in rest:
		match = re.match(r'^([A-Za-z][_0-9A-Za-z]*)=(.*)$', item)
		if not match:
			usage()
		key, value = match.groups()
		vars[key] = value

	# encode run string
	run_str = ''
	if script_dir:
		run_str += 'cd({}); '.format(mat_str(script_dir))
	for key, value in vars.items():
		run_str += '{} = {}; '.format(key, mat_str(value))
	run_str += '{}; '.format(script_name)
	run_str += 'quit; '

	# set up commands
	commands = ['matlab', '-nodesktop', '-nojvm', '-singleCompThread', '-r', run_str]

	# print
	sys.stderr.write(' '.join(commands) + '\n')
	# run
	os.execvp(commands[0], commands)
