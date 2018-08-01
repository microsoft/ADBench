"""Simple reader for PLY files"""

import numpy as np
import re

np_types = {
    'char'   : np.int8,
    'int8'   : np.int8,
    'uchar'  : np.uint8,
    'uint8'  : np.uint8,
    'short'  : np.int16,
    'int16'  : np.int16,
    'ushort' : np.uint16,
    'uint16' : np.uint16,
    'int'    : np.int32,
    'int32'  : np.int32,
    'uint'   : np.uint32,
    'uint32' : np.uint32,
    'float'  : np.float32,
    'float32': np.float32,
    'double' : np.float64,
    'float64': np.float64 }


class ScalarProperty(object):
    def __init__(self, type):
        assert(type in np_types)
        self.callback = None
        self.type = np_types[type]

    def read_data(self, file, element_num):
        p = np.fromfile(file, self.type, 1)
        if self.callback is not None:
            self.callback(element_num, p)


class ListProperty(object):
    def __init__(self, count_type, item_type):
        assert(count_type in np_types and item_type in np_types)
        self.callback = None
        self.count_type = np_types[count_type]
        self.item_type = np_types[item_type]

    def read_data(self, file, element_num):
        num_items = np.fromfile(file, self.count_type, 1)
        items = np.fromfile(file, self.item_type, num_items)
        if self.callback is not None:
            self.callback(element_num, items)


class Element(object):
    def __init__(self, count):
        self.count = int(count)
        self.properties = []
        self.property_dict = {}

    def add_property(self, line):
        tokens = line.split(" ")
        if tokens[1] == "list":
            assert(not tokens[4] in self.property_dict)
            self.properties.append(ListProperty(tokens[2], tokens[3]))
            name = tokens[4]
        else:
            assert(not tokens[2] in self.property_dict)
            self.properties.append(ScalarProperty(tokens[1]))
            name = tokens[2]
        self.property_dict[name] = self.properties[-1]


class PlyReader(object):
    def __init__(self, filename):
        self.elements = []
        self.element_dict = {}
        self.file = open(filename, 'rb')
        self.format = None

    def __del__(self):
        self.file.close()

    def comment_handler(self, line):
        pass

    def element_handler(self, line):
        tokens = line.split(" ")
        assert(not tokens[1] in self.element_dict)
        self.element_dict[tokens[1]] = Element(int(tokens[2]))
        self.elements.append(self.element_dict[tokens[1]])

    def property_handler(self, line):
        self.elements[-1].add_property(line)
        
    header_handlers = {'comment'  : comment_handler,
                       'element'  : element_handler,
                       'property' : property_handler }

    def read_header(self):
        # Magic bytes
        assert(self.file.read(3) == 'ply')
        self.file.readline()

        # Read header
        self.format = re.match('format (.*) 1.0', self.file.readline()).group(1)
        assert(self.format == 'binary_little_endian')
        line = self.file.readline().rstrip()
        while not line.startswith('end_header'):
            first_token = line.split(" ", 1)[0]
            assert(first_token in PlyReader.header_handlers)
            PlyReader.header_handlers[first_token](self, line)
            line = self.file.readline().rstrip()

    def read_data(self):
        for e in self.elements:
            for i in xrange(e.count):
                for p in e.properties:
                    p.read_data(self.file, i)


def read_ply_point_cloud(file):
    reader = PlyReader(file)
    reader.read_header()
    vertex_positions = np.empty((reader.element_dict['vertex'].count, 3))
    vertex_normals   = np.empty((reader.element_dict['vertex'].count, 3))

    def make_callback(vertex_array, n):
        def callback(enum, data):
            vertex_array[enum, n] = data
        return callback

    reader.element_dict['vertex'].property_dict[ 'x'].callback = make_callback(vertex_positions, 0)
    reader.element_dict['vertex'].property_dict[ 'y'].callback = make_callback(vertex_positions, 1)
    reader.element_dict['vertex'].property_dict[ 'z'].callback = make_callback(vertex_positions, 2)
    reader.element_dict['vertex'].property_dict['nx'].callback = make_callback(vertex_normals, 0)
    reader.element_dict['vertex'].property_dict['ny'].callback = make_callback(vertex_normals, 1)
    reader.element_dict['vertex'].property_dict['nz'].callback = make_callback(vertex_normals, 2)

    reader.read_data()
    return vertex_positions, vertex_normals
