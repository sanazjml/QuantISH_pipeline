#!/usr/bin/env python

#
# This has been very helpful:
# https://openslide.org/formats/mirax/
#

import math, os.path, re, struct
import collections
import ConfigParser
import PIL.Image, cStringIO
import zlib

def read_ini(filename):
	''' Read an ini file '''

	# Open file
	with open(filename, 'r') as stream:
		# Strip bom
		bom = stream.read(3)
		assert bom == '\xef\xbb\xbf'

		# Parse ini
		config = ConfigParser.RawConfigParser()
		config.readfp(stream)

	return config

def ind2sub(size, ind):
	# Loop
	subs = []
	stride = 1
	for s in size:
		# Shift in next digit
		subs.append( ind % s )
		# Move along
		ind /= s
		stride *= s

	return subs

def sub2ind(size, subs):
	# Loop
	ind = 0
	stride = 1
	for s, i in zip(size, subs):
		# Shift in next digit
		ind += stride*i
		# Move along
		stride *= s

	return ind

def detect_magic(data):
	import re

	# Windows bitmap
	if data.startswith('BM'):
		return 'bmp'
	# JPEG
	if data.startswith('\xff\xd8'):
		return 'jpg'
	# PNG
	if data.startswith('\x89PNG'):
		return 'png'
	# XML 
	if re.match(r'^<[A-Za-z]+>', data):
		return 'xml'

	return None

def div_int(a, b):
	# integer division with correct rounding
	y = a // b
	if 2*abs(a-b*y) >= abs(b):  # round half away from zero
		y += 1
	return y

class MRXSFile:
	def __init__(self, filename):
		# the .mrxs file is just a JPEG thumbnail, locate the directory 
		 # instead 
		if not os.path.isdir(filename):
			filename, _ = os.path.splitext(filename)
		self.__root = filename
		assert os.path.isdir(self.__root)

		# set up a read cache
		self.__read_dat_cache = collections.OrderedDict()

		# read the slide information
		self.__slidedat = read_ini(os.path.join(self.__root, 'Slidedat.ini'))
		# read the index
		self.__read_index(self.__get_filename('HIERARCHICAL', 'INDEXFILE'))

	def __get_filename(self, section, key):
		return os.path.join(self.__root, self.__slidedat.get(section, key))

	def __get_data_filename(self, file_id):
		return self.__get_filename('DATAFILE', 'FILE_{}'.format(file_id))

	def __get_param(self, section, key, type = str):
		return type(self.__slidedat.get(section, key))

	def __read_dat(self, filename):
		# serve from cache 
		if filename in self.__read_dat_cache:
			return self.__read_dat_cache[filename]

		# open the file
		with open(filename, 'rb') as stream:
			# get version
			version = stream.read(5)

			# switch version
			if   version == '01.01':
				# strip & check slide ID
				 # this time it's only half of the slide ID as UTF-16LE
				true_slideid = ( lambda s: s[ : (len(s) // 2) ] )(
					self.__get_param('GENERAL', 'SLIDE_ID') )
				slideid = stream.read(2 * len(true_slideid))
				assert slideid.decode('UTF-16LE') == true_slideid

				# get file version
				fileversion = stream.read(3)
				assert fileversion == '0\x000' or fileversion == '0\x001' or \
					fileversion == '0\x002' or fileversion == '0\x003'

				# skip zero padding
				padding = stream.read(256)
				assert all( b == '0' for b in padding )

			elif version == '01.02':
				# strip & check slide ID
				true_slideid = self.__get_param('GENERAL', 'SLIDE_ID')
				slideid = stream.read(len(true_slideid))
				assert slideid == true_slideid
			else:
				assert not 'invalid dat version' 

			# rest is payload
			skip = stream.tell()
			result = (stream.read(), skip)

			# update cache
			self.__read_dat_cache = {filename: result}

			return result

	def __read_tile(self, filename, data_offset, data_len):
		# read data
		data, skip = self.__read_dat(filename)
		# pull payload
		payload = data[(data_offset - skip) : (data_offset - skip + data_len)]
		assert len(payload) == data_len

		return payload

	def __get_grid_dims(self):
		return (self.__get_param('GENERAL', 'IMAGENUMBER_X', type = int),
			self.__get_param('GENERAL', 'IMAGENUMBER_Y', type = int))

	def __read_index(self, filename):
		# read the payload
		data, skip = self.__read_dat(filename)
		uint32_bytes = 4

		# get root pointers
		hier_root, nonhier_root = struct.unpack_from('<LL', data, offset = skip - skip)

		# walk through a linked list of pages & read records
		def read_pages(offset, payload_len):
			while offset != 0:
				# get record count & next pointer
				count, next_offset = struct.unpack_from('<LL', data, offset = offset - skip)
				offset += 2 * uint32_bytes

				# read records
				payload_fmt = '<' + 'L' * payload_len
				for i in xrange(count):
					# read the record
					payload = struct.unpack_from(payload_fmt, data, offset = offset - skip)
					offset += payload_len * uint32_bytes
					
					# emit 
					yield payload

				# follow the link to the next page
				offset = next_offset

		# get dimensions for translating the index
		grid_dims = self.__get_grid_dims()

		# create tile managers
		tiles = collections.OrderedDict()
		def add_tile(tag, key, value):
			# create slot if necessary
			if not tag in tiles:
				tiles[tag] = {}

			# add, checking that we don't overwrite stuff
			if key in tiles[tag]:
				import sys
				sys.stderr.write('warning: {} tile {} already exists, ignoring furher data'.format(tag, key) + '\n')
				return

			assert not key in tiles[tag]
			tiles[tag][key] = value

		# walk the hierarchical items
		offset = hier_root
		for hier in xrange(self.__get_param('HIERARCHICAL', 'HIER_COUNT', type = int)):
			for val in xrange(self.__get_param('HIERARCHICAL', 'HIER_{}_COUNT'.format(hier), type = int)):
				# get root pointer
				page_offset, = struct.unpack_from('<L', data, offset - skip)
				offset += uint32_bytes

				# extract records & add tiles
				for index, data_offset, data_len, file_id in read_pages(page_offset, 4):
					# get subscripts
					subs = tuple(ind2sub(grid_dims, index))

					# map data
					add_tile( 'HIER_{}_VAL_{}'.format(hier, val), subs,
						(self.__get_data_filename(file_id), data_offset, data_len) )

		# walk the nonhierarchical items
		offset = nonhier_root
		for nonhier in xrange(self.__get_param('HIERARCHICAL', 'NONHIER_COUNT', type = int)):
			for val in xrange(self.__get_param('HIERARCHICAL', 'NONHIER_{}_COUNT'.format(nonhier), type = int)):
				# get root pointer
				page_offset, = struct.unpack_from('<L', data, offset - skip)
				offset += uint32_bytes

				# walk the pages
				for index, _ , data_offset, data_len, file_id in read_pages(page_offset, 5):
					# add tile data
					add_tile( 'NONHIER_{}_VAL_{}'.format(nonhier, val), (index,),
						(self.__get_data_filename(file_id), data_offset, data_len) )

		# store the tile data
		self.__tiles = tiles

	def __get_tile_dims(self, tag):
		try:
			# get information section
			section = self.__get_param('HIERARCHICAL', '{}_SECTION'.format(tag))

			# get digitizer dimensions
			return (self.__get_param(section, 'DIGITIZER_HEIGHT', type = int),
				self.__get_param(section, 'DIGITIZER_WIDTH', type = int))

		except (ConfigParser.NoOptionError, ConfigParser.NoSectionError):
			return None

	def __parse_poss_table(self, payload, table_dims):
		payload = zlib.decompress(payload)

		stride = 9
		assert len(payload) == table_dims[0] * table_dims[1] * stride

		table = [None] * (table_dims[0] * table_dims[1])

		for i in xrange(len(payload) // stride):
			flag, x, y = struct.unpack_from('<BLL', payload, offset = i*stride)

			if flag == 0:
				assert x == 0 and y == 0   # NB. missing tile
				table[i] = None
			else:
				table[i] = (x, y)

		return table

	def __get_tile_poss_getter(self):
		# TODO: have fallback if this data is missing???

		# locate position NONHIER element 
		section = None
		for nonhier in xrange(self.__get_param('HIERARCHICAL', 'NONHIER_COUNT', type = int)):
			if (self.__get_param('HIERARCHICAL', 'NONHIER_{}_COUNT'.format(nonhier), type = int) == 1 and
					self.__get_param('HIERARCHICAL', 'NONHIER_{}_NAME'.format(nonhier)) == 'StitchingIntensityLayer' and
					self.__get_param('HIERARCHICAL', 'NONHIER_{}_VAL_0'.format(nonhier)) == 'StitchingIntensityLevel'):
				section = self.__get_param('HIERARCHICAL', 'NONHIER_{}_VAL_0_SECTION'.format(nonhier))
				break

		# get table size
		table_dims = (self.__get_param(section, 'COMPRESSSED_STITCHING_TABLE_WIDTH', type = int),
			self.__get_param(section, 'COMPRESSSED_STITCHING_TABLE_HEIGHT', type = int))

		# get tiles per camera block
		tile_factor = self.__get_param('GENERAL', 'CameraImageDivisionsPerSide', type = int)

		# get tile dimensions
		tw = self.__get_param(section, 'COMPRESSSED_STITCHING_ORIG_CAMERA_TILE_WIDTH', type = int) / tile_factor
		th = self.__get_param(section, 'COMPRESSSED_STITCHING_ORIG_CAMERA_TILE_HEIGHT', type = int) / tile_factor
		# get tile block overlap 
		ow = self.__get_param(section, 'COMPRESSED_STITCHING_ORIG_CAMERA_TILE_OVERLAP_X', type = int)
		oh = self.__get_param(section, 'COMPRESSED_STITCHING_ORIG_CAMERA_TILE_OVERLAP_Y', type = int)

		# parse first data fork 
		 # I don't know what the second is..
		tile = self.__tiles['NONHIER_{}_VAL_0'.format(nonhier)].values()[0]
		table = self.__parse_poss_table(self.__read_tile(*tile), table_dims)

		# look-up function
		def lookup_pos(x, y):
			# check bounds
			if not ( x < tile_factor * table_dims[0] and
					y < tile_factor * table_dims[1] ):
				return None
			
			# look up camera position
			i = x // tile_factor
			j = y // tile_factor
			result = table[i + table_dims[0] * j]

			# missing block data? predict from target
			if result is None:
				return ( x*tw-i*ow, y*th-j*oh )
			
			# adjust for the tile
			result = (result[0] + (x % tile_factor) * tw,
				result[1] + (y % tile_factor) * tw)

			return result

		return lookup_pos

	def __get_hier_level(self, tag):
		return int( re.sub(r'^HIER_(\d+)_VAL_(\d+)$', r'\2', tag) )

	def __get_canvas_dims(self, tag):
		# get size of the tile grid
		grid_dims = self.__get_grid_dims()
		# get tile size
		tile_dims = self.__get_tile_dims(tag)
		# get sparsity factor-- all integer math here
		ds_factor = 2 ** self.__get_hier_level(tag)

		return (div_int( grid_dims[0] * tile_dims[0], ds_factor ),
			div_int( grid_dims[1] * tile_dims[1], ds_factor ))

	def __get_fill_color(self, tag):
		try:
			# get information section
			section = self.__get_param('HIERARCHICAL', '{}_SECTION'.format(tag))

			# get fill color
			bgr_color = self.__get_param(section, 'IMAGE_FILL_COLOR_BGR', type = int)
			return (bgr_color // (255**2), bgr_color // (255**1), bgr_color // (255**0), 0)

		except ConfigParser.NoOptionError:
			return 0, 0, 0, 0

	def list(self, filter = re.compile('^.*$')):
		# list items
		for tag, tiles in ((tag, value)
				for tag, value in self.__tiles.items() if filter.match(tag)):
			# get tile dimensions
			tile_dims = self.__get_tile_dims(tag)

			# get format
			fmt = None
			if len(tiles) > 0:
				payload = self.__read_tile(*tiles.values()[0])

				fmt = detect_magic(payload)
				if fmt is None:
					fmt = 'dat'

				if tile_dims is None and fmt in ('bmp', 'jpg', 'png'):
					with PIL.Image.open(cStringIO.StringIO(payload)) as image:
						tile_dims = image.size

			# get canvas size
			pix_info = ''
			if tile_dims is not None:
				pix_info = ', {} pixels'.format('x'.join(str(d) for d in tile_dims))
	
			# get canvas size for HIER
			if tag.startswith('HIER'):
				canvas_dims = self.__get_canvas_dims(tag)
				pix_info = ', {} pixels'.format('x'.join(str(d) for d in canvas_dims))

			# print info
			print('{tag} with {tiles:,} tiles{pix_info} ({fmt})..'.format(
				tag = tag, tiles = len(tiles), pix_info = pix_info,
					fmt = fmt))

	def dump(self, outdir, outfn = None, filter = re.compile('^.*$'), crop = None, ds_factor = 1, progress = False, overlap = None):
		# dumps an item
		def dump_as(stem, payload, fmt = None, writer = lambda stream, payload: stream.write(payload)):
			# get format
			if fmt is None:
				fmt = detect_magic(payload)
				if fmt is None:
					fmt = 'dat'

			# figure out the file name
			filename = outfn
			if filename is None:
				filename = os.path.join(outdir, '{}.{}'.format(tag, fmt))

			# dump data
			with open(filename, 'wb') as stream:
				writer(stream, payload)
		
		# cache tile position getter
		get_tile_pos = None

		# loop through items
		for tag, tiles in ((tag, value)
					for tag, value in self.__tiles.items() if filter.match(tag)):
			# print info
			print('{tag} with {tiles:,} tiles..'.format(
				tag = tag, tiles = len(tiles)))

			# hierarchical or non-hier record?
			if tag.startswith('HIER'):
				# get tile dimensions
				tile_dims = self.__get_tile_dims(tag)
				orig_tile_dims = tile_dims
				# get canvas size
				canvas_dims = self.__get_canvas_dims(tag)

				# get hierarchical level
				level = self.__get_hier_level(tag)
				level_div = 2 ** level

				# track if we lost precision due to subpixel positioning
				lost_prec = False

				# handle downsampling
				if not ds_factor == 1:
					# check for lost precision
					if not lost_prec:
						if not (tile_dims[0] % ds_factor == 0 and tile_dims[1] % ds_factor == 0):
							lost_prec = True
						if not (canvas_dims[0] % ds_factor == 0 and canvas_dims[0] % ds_factor == 0):
							lost_prec = True
						if not crop is None:
							if not (crop['x'] % ds_factor == 0 and crop['y'] % ds_factor == 0 and
									crop['w'] % ds_factor == 0 and crop['x'] % ds_factor == 0):
								lost_prec = True

					# downsample tile size
					tile_dims = (div_int(tile_dims[0], ds_factor), div_int(tile_dims[1], ds_factor))
					# downsample canvas
					canvas_dims = (div_int(canvas_dims[0], ds_factor), div_int(canvas_dims[1], ds_factor))

					# update crop region
					if not crop is None:
						crop = {'x': div_int(crop['x'], ds_factor), 'y': div_int(crop['y'], ds_factor),
							'w': div_int(crop['w'], ds_factor), 'h': div_int(crop['h'], ds_factor)}
				
				# compute split tile size
				if level > 0:
					# lost precision?
					if not lost_prec:
						if not (tile_dims[0] % level_div == 0 and tile_dims[0] % level_div == 0):
							lost_prec = True

					# get size anyway..
					subimg_dims = (div_int(tile_dims[0], level_div), div_int(tile_dims[1], level_div))

				# summon getter
				if get_tile_pos is None:
					if overlap:
						get_tile_pos = self.__get_tile_poss_getter()

						if not ds_factor == 1:
							orig_getter = get_tile_pos

							# TODO: cannot update lost_prec in getter.. 
							 # do it here regardless, we likely lose it anyway 
							lost_prec = True

							def getter(x, y):
								pos = orig_getter(x, y)
								if pos is None:
									return pos

								return div_int(pos[0], ds_factor), div_int(pos[1], ds_factor)

							get_tile_pos = getter

					else:
						get_tile_pos = lambda x, y: (x * orig_tile_dims[0], y * orig_tile_dims[1])

				# create the canvas
				if crop is None:
					canvas = PIL.Image.new('RGBA', size = canvas_dims,
						color = self.__get_fill_color(tag))
				else:
					canvas = PIL.Image.new('RGBA', size = (crop['w'], crop['h']),
						color = self.__get_fill_color(tag))

				# extract tiles
				for index, ((x, y), tile) in enumerate(sorted(tiles.items(),
						key = lambda ((x, y), _): (y, x))):
					# get tile pos 
					dx, dy = get_tile_pos(x, y)
					if level > 0:
						if not lost_prec:
							if not (dx % level_div == 0 and dy % level_div == 0):
								lost_prec = True
						dx, dy = div_int(dx, level_div), div_int(dy, level_div)

					# cull out the image
					if crop is not None:
						if not ( dx + tile_dims[0] > crop['x'] and dx < crop['x'] + crop['w'] and
								dy + tile_dims[1] > crop['y'] and dy < crop['y'] + crop['h'] ):
							continue

					# print progress
					if progress:
						sys.stderr.write('{clear}Tile {i}/{n} {prc:.1f}%..'.format(
							clear = '\x1b[G\x1b[K', i = index+1, n = len(tiles), prc = 100. * index / len(tiles)))

					# pull data
					payload = self.__read_tile(*tile)
					# parse
					img_data = PIL.Image.open(cStringIO.StringIO(payload))
					assert img_data.size[0] == orig_tile_dims[0] and img_data.size[1] == orig_tile_dims[1]

					# downsample image
					if not ds_factor == 1:
						img_data = img_data.resize(size = tile_dims, resample = PIL.Image.NEAREST)

					# paint
					if level == 0 or not overlap:
						if crop is None:
							canvas.paste(img_data, box = (dx, dy))
						else:
							canvas.paste(img_data, box = (dx - crop['x'], dy - crop['y']))
					else:
						# get crop origin
						cx, cy = 0, 0
						if crop is not None:
							cx, cy = crop['x'], crop['y']

						# TODO: need a Z-buffer & reverse to accelerate this

						# split tile
						for j in xrange(level_div):
							for i in xrange(level_div):
								# get subimage position
								pos = get_tile_pos(x+i, y+j)
								if pos is None:
									continue   # NB. subimage outside of image

								# compute destination
								dx, dy = pos
								if not lost_prec:
									if not (dx % level_div == 0 and dy % level_div == 0):
										lost_prec = True
								dx, dy = div_int(dx, level_div), div_int(dy, level_div)

								# get bounding box for the source image--
								 # we already checked if we lost precision
								sx, sy = ( div_int( i*tile_dims[0], level_div ),
									div_int( j*tile_dims[1], level_div ) )
								ex, ey = tile_dims[0], tile_dims[1]

								# paint
								canvas.paste( img_data.crop( box = (sx, sy, ex, ey) ),
									box = (dx - cx, dy - cy) )

				# dump it
				if progress:
					sys.stderr.write('{clear}Writing..'.format(
						clear = '\x1b[G\x1b[K'))
				fmt = 'png'
				dump_as( tag, canvas, fmt = fmt, writer = lambda stream, canvas:
					canvas.save(stream, format = fmt) )

				# clean up progress
				if progress:
					sys.stderr.write('{clear}'.format(
						clear = '\x1b[G\x1b[K'))

				# print a warning if we lost precision
				if lost_prec:
					sys.stderr.write('warning: lost precision in {}'.format(tag) + '\n')

			else:
				# dump items as-is
				if len(tiles) == 1:
					dump_as( tag, self.__read_dat(tiles.values()[0]) )
				else:
					for i, tile in tiles.items():
						dump_as( '{}.{}'.format(tag, i+1), self.__read_dat(tile) )

def glob2re(pattern):
	tokens = re.findall('([*?]|[^*?]+)', pattern)
	return re.compile('^' + ''.join({'?': '.', '*': '.*'}.get(
		token, re.escape(token)) for token in tokens) + '$')

def parse_geom(geom):
	# NB. imagemagic spec
	match = re.match(r'''
		^ (?P<w> \d+)? (?: x (?P<h> \d+) )?
			(?: [+] (?P<x> \d+) (?: [+] (?P<y> \d+)? )? )? $
	''', geom, flags = re.X)
	result = match.groupdict()
	for key in ('w', 'h', 'x', 'y'):
		if result[key] is None:
			result[key] = 0
		else:
			result[key] = int(result[key])
	return result

if __name__ == '__main__':
	import argparse, os, sys

	# Set up the command line
	parser = argparse.ArgumentParser()
	parser.add_argument('-g', metavar = 'glob', default = '*',
		help = 'filter for tags to be extracted (default: "*")')
	parser.add_argument('-o', metavar = 'dir', default = '.',
		help = 'output directory (default: ".")')
	parser.add_argument('-O', metavar = 'file', default = None,
		help = 'output filename (default: automatic)')
	parser.add_argument('-d', dest = 'list', action = 'store_false', default = False,
		help = 'dump items (default)')
	parser.add_argument('-l', dest = 'list', action = 'store_true',
		help = 'list items (do not write anything)') 
	parser.add_argument('-c', metavar = 'crop', default = '',
		help = 'extract the specified region only')
	parser.add_argument('-D', metavar = 'factor', default = 1, type = int,
		help = 'downsample each tile by an integer factor') 
	parser.add_argument('-P', dest = 'progress', action = 'store_true', default = False,
		help = 'print progress')
	parser.add_argument('-r', dest = 'overlap', action = 'store_const', const = 'pred',
		help = 'eliminate predicted overlap')
	parser.add_argument('filename')

	# Parse arguments
	args = parser.parse_args()
	# Get geometry
	crop_geom = None
	if args.c:
		crop_geom = parse_geom(args.c)

	# Make sure the destination exists
	if os.path.exists(args.o):
		for _, sub_dirs, sub_files in os.walk(args.o):
			if len(sub_dirs + sub_files) > 0:
				sys.stderr.write('warning: output directory ''{}'' exists and is not empty'.format(args.o) + '\n')
				break
	else:
		os.mkdir(args.o)

	# Open file & dump stuff
	mrxs = MRXSFile(args.filename)
	if args.list:
		mrxs.list(filter = glob2re(args.g))
	else:
		mrxs.dump(args.o, args.O, filter = glob2re(args.g), crop = crop_geom,
			overlap = args.overlap, ds_factor = args.D, progress = args.progress)
