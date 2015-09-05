"""Simple writer for PLY files"""

import numpy as np

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
    def __init__(self, type, name):
        assert(type in np_types)
        self.callback = None
        self.type = np_types[type]
        self.typename = type
        self.name = name

    def write_header(self, file):
        file.write("property " + self.typename + " " + self.name + "\n")

    def write_data(self, file, element_num):
        assert(self.callback is not None)
        self.callback(element_num).astype(self.type).tofile(file)


class ListProperty(object):
    def __init__(self, count_type, item_type, name):
        assert(count_type in np_types and item_type in np_types)
        self.callback = None
        self.count_type_name = count_type
        self.item_type_name = item_type
        self.count_type = np_types[count_type]
        self.item_type = np_types[item_type]
        self.name = name

    def write_header(self, file):
        file.write("property list " + self.count_type_name + " " + self.item_type_name + " " + self.name + "\n")

    def write_data(self, file, element_num):
        assert(self.callback is not None)
        items = self.callback(element_num)
        num_items = np.array(len(items), self.count_type)
        num_items.tofile(file)
        items.astype(self.item_type).tofile(file)


class Element(object):
    def __init__(self, count, name):
        self.count = count
        self.name = name
        self.properties = []
        self.property_dict = {}

    def write_header(self, file):
        file.write("element " + self.name + " " + str(self.count) + "\n")
        for p in self.properties:
            p.write_header(file)

    def add_property(self, p):
        self.properties.append(p)
        self.property_dict[p.name] = p


class PlyWriter(object):
    def __init__(self, filename):
        self.elements = []
        self.element_dict = {}
        self.file = open(filename, 'wb')
        self.format = 'binary_little_endian'

    def __del__(self):
        self.file.close()

    def add_element(self, e):
        self.elements.append(e)
        self.element_dict[e.name] = e

    def write_header(self):
        # Magic bytes
        self.file.write("ply\n")

        # Write header
        self.file.write("format %s 1.0\n" % self.format)
        for e in self.elements:
            e.write_header(self.file)
        self.file.write("end_header\n")

    def write_data(self):
        for e in self.elements:
            for i in xrange(e.count):
                for p in e.properties:
                    p.write_data(self.file, i)


def write_ply_point_cloud(file, positions, normals):
    writer = PlyWriter(file)
    assert(positions.shape[0] == normals.shape[0])
    n_points = positions.shape[0]

    def make_callback(vertex_array, n):
        def callback(enum):
            return vertex_array[enum, n]
        return callback

    vert_e = Element(n_points, 'vertex')
    vert_e.add_property(ScalarProperty('float', 'x'))
    vert_e.add_property(ScalarProperty('float', 'y'))
    vert_e.add_property(ScalarProperty('float', 'z'))
    vert_e.add_property(ScalarProperty('float', 'nx'))
    vert_e.add_property(ScalarProperty('float', 'ny'))
    vert_e.add_property(ScalarProperty('float', 'nz'))
    vert_e.property_dict[ 'x'].callback = make_callback(positions, 0)
    vert_e.property_dict[ 'y'].callback = make_callback(positions, 1)
    vert_e.property_dict[ 'z'].callback = make_callback(positions, 2)
    vert_e.property_dict['nx'].callback = make_callback(normals, 0)
    vert_e.property_dict['ny'].callback = make_callback(normals, 1)
    vert_e.property_dict['nz'].callback = make_callback(normals, 2)
    writer.add_element(vert_e)

    writer.write_header()
    writer.write_data()
