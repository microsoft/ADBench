import vtk
import os
import numpy as np
from vtk.util.numpy_support import vtk_to_numpy, numpy_to_vtk


PWD = os.path.dirname(os.path.abspath(__file__))
RSPYTHON_LOCATION = os.path.join(PWD, '../../../../external')
import sys
sys.path.insert(0, RSPYTHON_LOCATION)

#from rspython.vtk_.convenience import make_vtkPoints, make_vtkCellArray
def make_vtkPoints(P):
    P = np.atleast_2d(P)
    points = vtk.vtkPoints()
    points.SetNumberOfPoints(P.shape[0])
    for i, p in enumerate(P):
        points.SetPoint(i, *p)
    return points
def make_vtkCellArray(T):
    cell_array = vtk.vtkCellArray()
    for t in T:
        cell_array.InsertNextCell(len(t))
        for i in t:
            cell_array.InsertCellPoint(i)
    return cell_array
#from rspython.vtk_.jet import get_jet_lut

class Troupe(object):
    def _process_kwargs(self, **kwargs):
        for key, value in kwargs.iteritems():
            setter = getattr(self, 'set_' + key)
            try:
                setter(*value)
            except:
                setter(value)
    
    def set_color(self, color):
        for actor in self.actors:
            actor.GetProperty().SetColor(color)

    def toggle_visibility(self):
        for actor in self.actors:
            actor.SetVisibility(1 - actor.GetVisibility())

    def set_visible(self, should_be_visible):
        for actor in self.actors:
            actor.SetVisibility(1 if should_be_visible else 0)

    def set_opacity(self, opacity):
        for actor in self.actors:
            actor.GetProperty().SetOpacity(opacity)

    def set_pickable(self, pickable):
        for actor in self.actors:
            actor.SetPickable(pickable)

class SingleActorTroupe(Troupe):
    def get_opacity(self):
        return self.actor.GetProperty().GetOpacity()

    def toggle_opacity(self):
        current_opacity = self.get_opacity()
        if current_opacity != 1.0:
            self._last_opacity = current_opacity
            self.set_opacity(1.0)
        else:
            if hasattr(self, '_last_opacity'):
                self.set_opacity(self._last_opacity)

    @property
    def actors(self):
        return [self.actor]
        
class AxesTroupe(SingleActorTroupe):

    def __init__(self, **kwargs):

        self.poly_data = vtk.vtkPolyData()

        self.axes = vtk.vtkAxes()
        self.axes.SetScaleFactor(0.01)
        
        self.glyph = vtk.vtkTensorGlyph()
        self.glyph.ExtractEigenvaluesOff()
        self.glyph.ThreeGlyphsOff()
        self.glyph.SymmetricOff()
        self.glyph.SetSourceConnection(self.axes.GetOutputPort())
        self.glyph.SetInput(self.poly_data)

        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.glyph.GetOutputPort())

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)

        self._process_kwargs(**kwargs)


    def _make_orientation_tensors(self, orientations):
        """Here orientations is self.n_axes x 3 x 3 rotation matrices."""

        tensors = numpy_to_vtk(orientations.reshape(-1, 9), True)
        return tensors


    def set(self, positions = None, orientations = None):
        if positions is not None:
            self.poly_data.SetPoints(make_vtkPoints(positions))

        if orientations is not None:
            tensors = self._make_orientation_tensors(orientations)
            self.poly_data.GetPointData().SetTensors(tensors)


class PointsTroupe(SingleActorTroupe):

    def __init__(self, size=4, color=(0.9, 0.9, 0.9), **kwargs):
        kwargs["color"] = color
        kwargs["size"] = size

        self.poly_data = vtk.vtkPolyData()

        self.extractor = vtk.vtkExtractPolyDataGeometry()
        self.extractor.SetInput(self.poly_data)
        self.constant_function = vtk.vtkQuadric()
        self.constant_function.SetCoefficients(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0)
        # Filter disabled by default
        self.extractor.SetImplicitFunction(self.constant_function)
        self.frustum = None
        
        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.extractor.GetOutputPort())

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)
        self._process_kwargs(**kwargs)

    def get_filtered_ids(self):
        if self.frustum is None:
            return np.arange(self.poly_data.GetNumberOfCells())
        filtered_ids = self.extractor.GetOutput().GetVerts().GetData()
        return vtk_to_numpy(filtered_ids)[1::2]

    def set_filter_enabled(self, to_filter):
        if to_filter and self.frustum is not None:
            self.extractor.SetImplicitFunction(self.frustum)
        else:
            self.extractor.SetImplicitFunction(self.constant_function)
        self.extractor.Update()

    def set_filtering_frustum(self, frustum_planes):
        self.frustum = frustum_planes
        self.set_filter_enabled(frustum_planes is not None)

    def set_positions(self, positions):
        points = make_vtkPoints(positions)
        self.poly_data.SetPoints(points)
        self.poly_data.SetVerts(make_vtkCellArray(zip(range(positions.shape[0]))))

    def set_normals(self, normals):
        self.poly_data.GetPointData().SetNormals(numpy_to_vtk(normals, True))

    def set_size(self, size):
        self.actor.GetProperty().SetPointSize(size)


class PlanesTroupe(SingleActorTroupe):
    def __init__(self, **kwargs):
        self.hull = vtk.vtkHull()
        self.poly_data = vtk.vtkPolyData()
        self.extractor = vtk.vtkExtractEdges()
        self.extractor.SetInput(self.poly_data)
        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.extractor.GetOutputPort())
        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)
        self._process_kwargs(**kwargs)

    def set_planes(self, planes):
        self.hull.SetPlanes(planes)
        coord_bound = 100000.0
        self.hull.GenerateHull(self.poly_data, -coord_bound, coord_bound, -coord_bound, coord_bound, -coord_bound, coord_bound)


class SpheresTroupe(SingleActorTroupe):
    def __init__(self, radius=0.001, phi_resolution=8, theta_resolution=8, **kwargs):
        kwargs['radius'] = radius
        kwargs['phi_resolution'] = phi_resolution
        kwargs['theta_resolution'] = theta_resolution

        self.poly_data = vtk.vtkPolyData()

        self.sphere_source = vtk.vtkSphereSource()

        self.glyph = vtk.vtkGlyph3D()
        self.glyph.GeneratePointIdsOn()
        self.glyph.SetInput(self.poly_data)
        self.glyph.SetSourceConnection(self.sphere_source.GetOutputPort())
        self.glyph.SetColorModeToColorByScalar()
        self.glyph.SetScaleModeToDataScalingOff()

        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.glyph.GetOutputPort())

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)
        self.actor.GetProperty().BackfaceCullingOn()

        self._process_kwargs(**kwargs)
        
    def vtk_point_id_to_point_index(self, point_id):
        """Maps the vtk point id that comes from (e.g.) a vtkPointPicker back to a point index."""
        point_indices = self.glyph.GetOutput().GetPointData().GetArray("InputPointIds")
        return int(point_indices.GetTuple1(point_id))

    def set_radius(self, radius):
        self.sphere_source.SetRadius(radius)

    def set_phi_resolution(self, phi_resolution):
        self.sphere_source.SetPhiResolution(phi_resolution)

    def set_theta_resolution(self, theta_resolution):
        self.sphere_source.SetThetaResolution(theta_resolution)

    def set_positions(self, positions):
        self.poly_data.SetPoints(make_vtkPoints(positions))

    def set_sphere_colors(self, colors):
        self.poly_data.GetPointData().SetScalars(numpy_to_vtk(colors, True))
        

class MultipleSphereActorsTroupe(Troupe):
    def __init__(self, radius=0.001, phi_resolution=8, theta_resolution=8, num_spheres=1, **kwargs):
        kwargs['radius'] = radius
        kwargs['phi_resolution'] = phi_resolution
        kwargs['theta_resolution'] = theta_resolution

        self.sphere_source = vtk.vtkSphereSource()
        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.sphere_source.GetOutputPort())

        self.actors = []
        for i in xrange(num_spheres):
            actor = vtk.vtkActor()
            actor.SetMapper(self.mapper)
            actor.GetProperty().BackfaceCullingOn()
            self.actors.append(actor)
        
        self._process_kwargs(**kwargs)

    def set_radius(self, radius):
        self.sphere_source.SetRadius(radius)

    def set_phi_resolution(self, phi_resolution):
        self.sphere_source.SetPhiResolution(phi_resolution)

    def set_theta_resolution(self, theta_resolution):
        self.sphere_source.SetThetaResolution(theta_resolution)

    def set_positions(self, positions):
        assert(positions.shape[0] == len(self.actors))
        for i in xrange(positions.shape[0]):
            self.actors[i].SetPosition(positions[i, :])

    def set_sphere_visibility(self, visarray):
        assert(visarray.size == len(self.actors))
        for i in xrange(visarray.size):
            self.actors[i].SetVisibility(1 if visarray[i] else 0)

class ArrowsTroupe(SingleActorTroupe):

    def __init__(self, scale=0.01, **kwargs):
        kwargs["scale"] = scale

        self.poly_data = vtk.vtkPolyData()

        self.arrow_source = vtk.vtkArrowSource()

        self.transform = vtk.vtkTransform()
        
        self.transform_poly_data_filter = vtk.vtkTransformPolyDataFilter()
        self.transform_poly_data_filter.SetTransform(self.transform)
        self.transform_poly_data_filter.SetInputConnection(self.arrow_source.GetOutputPort())

        self.glyph = vtk.vtkGlyph3D()
        self.glyph.OrientOn()
        self.glyph.SetVectorModeToUseNormal()
        self.glyph.SetInput(self.poly_data)
        self.glyph.SetSourceConnection(self.transform_poly_data_filter.GetOutputPort())

        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.glyph.GetOutputPort())

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)

        self._process_kwargs(**kwargs)

    def set_scale(self, scale):
        self.transform.Scale(scale, scale, scale)

    def set_positions(self, positions):
        self.poly_data.SetPoints(make_vtkPoints(positions))

    def set_directions(self, directions):
        self.poly_data.GetPointData().SetNormals(numpy_to_vtk(directions, True))

class TubesTroupe(SingleActorTroupe):

    def __init__(self, radius=0.0003, number_of_sides=6, **kwargs):
        kwargs["number_of_sides"] = number_of_sides
        kwargs["radius"] = radius

        self.poly_data = vtk.vtkPolyData()

        self.tube_filter = vtk.vtkTubeFilter()
        self.tube_filter.SetInput(self.poly_data)

        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInputConnection(self.tube_filter.GetOutputPort())

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)
        self.actor.GetProperty().BackfaceCullingOn()

        self._process_kwargs(**kwargs)

    def set_radius(self, radius):
        self.tube_filter.SetRadius(radius)

    def set_start_end_indices(self, start_indices, end_indices):
        self.poly_data.SetLines(make_vtkCellArray(zip(start_indices, end_indices)))

    def set_number_of_sides(self, num):
        self.tube_filter.SetNumberOfSides(num)

    def set_points(self, points):
        self.poly_data.SetPoints(make_vtkPoints(points))

    def set_start_end_points(self, start_points, end_points):
        start_points = np.asarray(start_points)
        end_points = np.asarray(end_points)
        n_tubes = start_points.shape[0]
        
        self.set_start_end_indices(range(n_tubes), range(n_tubes, 2*n_tubes))
        points = np.r_[start_points, end_points]
        self.set_points(points)

class SurfaceTroupe(SingleActorTroupe):

    def __init__(self, **kwargs):

        self.poly_data = vtk.vtkPolyData()

        self.mapper = vtk.vtkPolyDataMapper()
        self.mapper.SetInput(self.poly_data)

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)

        self._process_kwargs(**kwargs)

    def set_polygons(self, polygons):
        self.poly_data.SetPolys(make_vtkCellArray(polygons))
    
    def set_points(self, points):
        self.poly_data.SetPoints(make_vtkPoints(points))

class LoopSurfaceTroupe(SingleActorTroupe):

    def __init__(self, **kwargs):

        self.poly_data = vtk.vtkPolyData()

        self.subdivider = vtk.vtkLoopSubdivisionFilter()
        self.subdivider.SetInput(self.poly_data)
        self.subdivider.SetNumberOfSubdivisions(2)

        self.mapper = vtk.vtkDataSetMapper()
        self.mapper.SetInputConnection(self.subdivider.GetOutputPort())

        self.actor = vtk.vtkActor()
        self.actor.SetMapper(self.mapper)

        self._process_kwargs(**kwargs)

    def set_polygons(self, polygons):
        self.poly_data.SetPolys(make_vtkCellArray(polygons))
    
    def set_points(self, points):
        self.poly_data.SetPoints(make_vtkPoints(points))


class MeshTroupe(TubesTroupe):

    def set_polygons(self, polygons):

        start_indices = []
        end_indices = []

        for poly in polygons:
            n = len(poly)
            for i in range(n):
                svert = poly[i]
                evert = poly[(i+1)%n]
                if svert < evert:
                    start_indices.append(svert)
                    end_indices.append(evert)

        self.set_start_end_indices(start_indices, end_indices)

class TextWidgetTroupe(SingleActorTroupe):

    def __init__(self, **kwargs):
        text_rep = vtk.vtkTextRepresentation();
        text_rep.GetPositionCoordinate().SetValue(0.01, 0.02)
        text_rep.GetPosition2Coordinate().SetValue(.3, .96)

        text_widget = vtk.vtkTextWidget()

        text_widget.SetRepresentation(text_rep)

        text_actor = text_widget.GetTextActor()
        text_actor.SetTextScaleModeToNone()
        text_actor.UseBorderAlignOn()
        text_actor.SetMaximumLineHeight(0.03)

        text_prop = text_rep.GetTextActor().GetTextProperty()
        text_prop.SetColor(0., 0, 0)
        text_prop.SetFontSize(12)
        text_prop.SetJustificationToLeft()
        text_prop.SetVerticalJustificationToTop()

        self.text_widget = text_widget
        self.text_rep = text_rep
        self.text_prop = text_prop

        self._process_kwargs(**kwargs)

    def set_interactor(self, interactor):
        self.text_widget.SetInteractor(interactor)
        self.text_widget.SelectableOff()
        self.text_widget.On()

    def set_text(self, text):
        print text
        self.text_rep.GetTextActor().SetInput(text)

class TextTroupe(SingleActorTroupe):

    def __init__(self, font_size=14, color=(0.0, 0.0, 0.0), relative_position=(0, 1), absolute_offset=(10, -10), text="", **kwargs):
        kwargs["text"] = text
        kwargs['color'] = color
        kwargs["absolute_offset"] = absolute_offset
        kwargs["relative_position"] = relative_position
        kwargs["font_size"] = font_size

        self.actor = vtk.vtkTextActor()

        self.text_property = self.actor.GetTextProperty()
        self.text_property.SetFontFamilyToCourier()
        self.text_property.SetVerticalJustificationToTop()
        
        self.relpos_coord = vtk.vtkCoordinate()
        self.relpos_coord.SetCoordinateSystemToNormalizedViewport()
        self.actor.GetPositionCoordinate().SetCoordinateSystemToViewport()
        self.actor.GetPositionCoordinate().SetReferenceCoordinate(self.relpos_coord)

        self._process_kwargs(**kwargs)

    def set_absolute_offset(self, x, y):
        self.actor.SetPosition(x, y)

    def set_color(self, r, g, b):
        self.text_property.SetColor(r, g, b)

    def set_relative_position(self, x, y):
        self.relpos_coord.SetValue(x, y)

    def set_text(self, text):
        if len(text) == 0:
            text = "."
            self.set_visible(False)
        else:
            self.set_visible(True)
        self.actor.SetInput(text)

    def set_font_size(self, font_size):
        self.text_property.SetFontSize(font_size)

    def set_alignment(self, alignment):
        { 'left': self.text_property.SetJustificationToLeft,
          'centre': self.text_property.SetJustificationToCentered,
          'right': self.text_property.SetJustificationToRight }[alignment]()

class ColorBarTroupe(SingleActorTroupe):

    def __init__(self, lut=None, **kwargs):
        self.actor = vtk.vtkScalarBarActor()
        self.actor.SetMaximumNumberOfColors(400)
        
        if lut is None:
            lut = get_jet_lut()

        self.lut = lut
        self.actor.SetLookupTable(lut)
        self.actor.SetWidth(0.05)
        self.actor.SetPosition(0.95, 0.1)
        self.actor.SetLabelFormat("%.3g")
        self.actor.VisibilityOn()

            
