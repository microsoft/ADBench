"""FIXME: This is currently broken.  It needs to be updated to use the new subdiv library."""

from ezvtk import troupe
import numpy as np

from mold.loop.uniform_parameterisation import uniform_parameterisation

class SubdivSurfaceTroupe(troupe.SingleActorTroupe):

    def __init__(self, model, sampling_rate=3, **kwargs):
        kwargs["sampling_rate"] = sampling_rate

        self.surface_troupe = troupe.SurfaceTroupe()
        self.actor = self.surface_troupe.actor
        
        self.model = model
        n_tris = self.model.number_of_faces()
        triangles = []
        for i_tri in range(n_tris):
            triangles.append(self.model.face_vertex_indices(i_tri))
        self.triangles = np.asarray(triangles)

        self.points = np.zeros((self.model.number_of_vertices(), 3))

        self._process_kwargs(**kwargs)

    def update_surface(self):
        self.sampled_patch_indices, self.sampled_coordinates, self.sampled_triangles, _, = uniform_parameterisation(self.triangles, self.sampling_rate)
        self.surface_troupe.set_polygons(self.sampled_triangles)
        sampled_surface_points = self.model.M(self.sampled_patch_indices, self.sampled_coordinates, self.points)
        self.surface_troupe.set_points(sampled_surface_points)

    def set_points(self, points):
        self.points = points
        self.update_surface()

    def set_sampling_rate(self, sampling_rate):
        sampling_rate = max(1, sampling_rate)
        self.sampling_rate = sampling_rate
        self.update_surface()

    