"""A script to display the hand model."""
import os

from pychira.model import load_model
from pychira import util

util.add_ezvtk_to_path()
import ezvtk.vis
import ezvtk.troupe

import vtk

model_path = os.path.join(util.get_chira_root(), 'data/models/hand-model-v3/exported_template_from_blender')

model = load_model(model_path)

class ModelViewer():

    def __init__(self):

        self.viewer = ezvtk.vis.Viewer()

        # Add triangular mesh.
        self.mesh_troupe = ezvtk.troupe.MeshTroupe()
        self.mesh_troupe.set_polygons(model.triangles)
        self.mesh_troupe.set_points(model.base_positions)

        # Also add points for easy picking with the mouse.
        self.vertices_troupe = ezvtk.troupe.SpheresTroupe(color=(.2, .5, .7), radius=0.002)
        self.vertices_troupe.set_positions(model.base_positions)

        # Text to display what vertex is picked.
        self.text_troupe = ezvtk.troupe.TextTroupe()
        self.text_troupe.set_text("Move the mouse on top of a vertex and press v to get it's index.")

        # Add these to the viewer.
        self.viewer.add_troupes(self.mesh_troupe, self.vertices_troupe, self.text_troupe)
        
        self.viewer.add_key_callback('v', self.viewer.pick)
        self.viewer.add_pick_callback(self.pick)

    def pick(self, object, event):
        if object.GetActor() == self.vertices_troupe.actor:
            i_vertex = self.vertices_troupe.vtk_point_id_to_point_index(self.viewer.picker.GetPointId())
            self.text_troupe.set_text('Vertex Index is %d' % i_vertex)
            self.viewer.render()

    def start(self):
        self.viewer.start()

viewer = ModelViewer()

viewer.start()
