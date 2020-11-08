#!/usr/bin/env python

import csv
import os, os.path
import re

def make_key(file_path):
	return re.sub(r'[^_0-9A-Za-z]', '_', os.path.basename(file_path))

def glob2re(pattern):
	s = ''
	for piece in re.findall(r'([^?*]+|[*]|[?])', pattern):
		s += {'*': '.*', '?': '.'}.get(piece, re.escape(piece))
	return re.compile(s)

class FileCompare:
	def __init__(self, file_path):
		if os.path.exists(file_path):
			self.__file_path = file_path
			self.__cmp = os.path.samefile
		else:
			self.__file_path = None
			self.__cmp = lambda x, y: False

	def __call__(self, file_path):
		return self.__cmp(self.__file_path, file_path)

if __name__ == '__main__':
	import sys

	# check usage
	try:
		try:
			_, dest, pattern = sys.argv
		except ValueError:
			_, dest = sys.argv
			pattern = '*'
	except ValueError:
		sys.stderr.write('Usage: {} path [pattern]'.format(sys.argv[0]) + '\n')
		sys.exit(1)

	# figure out the directory & index file
	if os.path.isdir(dest) or dest.endswith('/'):
		dir_path = dest
		index_path = os.path.join(dir_path, '_index')
	else:
		dir_path = os.path.dirname(dest)
		index_path = dest

	# slurp in current keys
	keys = {}
	if os.path.exists(index_path):
		with open(index_path, 'r') as stream:
			reader = csv.DictReader(stream, dialect = 'excel-tab')
			for line in reader:
				keys[line['File']] = line['Key']

	# compile pattern
	pattern_re = glob2re(pattern)

	# stat files
	index_data = []
	eq_index_file = FileCompare(index_path)
	for path, dir_names, file_names in os.walk(dir_path):
		for name in file_names:
			if pattern_re.match(name):
				file_path = os.path.realpath(os.path.join(path, name))
				if not eq_index_file(file_path):
					key = keys.get(file_path, make_key(file_path))
					index_data.append((key, file_path))

	# dump data
	with open(index_path, 'w') as stream:
		writer = csv.DictWriter(stream, ('Key', 'File'),
			dialect = 'excel-tab', quoting = csv.QUOTE_ALL)
		writer.writeheader()
		for key, file_path in index_data:
			writer.writerow({'Key': key, 'File': file_path})
