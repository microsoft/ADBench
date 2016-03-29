"""A script to display the hand model."""
import os
import math
import numpy as np

from pychira import optimizer, pose_sequence, util
from pychira.model import load_model
from pychira.pose_sequence import NUM_BONES
from local_setup import local_annotation_sequence

util.add_ezvtk_to_path()
import ezvtk.vis
import ezvtk.troupe

import vtk

DELTA = 0.1
AXIS_NAMES = ['Flexion', 'Abduction', 'Twist']
PALM_VERTICES = [ 0, 8, 180, 181, 243, 277, 293, 320, 322, 327, 328, 329 ]
MARKER_COLOUR = (0.0, 0.7, 0.0)
MAX_OPT_POINTS = 1000
SURFACE_COLOUR = (0.710,0.000,0.000)
SURFACE_OPACITY = 0.6

class ViewMode(object):
    def __init__(self, model_viewer, model):
        self.model_viewer = model_viewer
        self.model = model

    def get_global_pos_header(self):
        return "Global transform   \n"

    def get_text_color(self):
        return (0.0, 0.0, 0.0) # black

    def markers_changed(self):
        self.model_viewer.update_markers()

    def pose_changed(self):
        self.model_viewer.update_mesh()

    def text_changed(self):
        self.model_viewer.update_text_boxes()

class EditBoneMode(ViewMode):
    def __init__(self, model_viewer, model):
        super(EditBoneMode, self).__init__(model_viewer, model)
        self.i_bone = 0
        self.i_axis = 0

    def change_i_bone_and_i_axis(self, delta_i_bone, delta_i_axis):
        # Update bone and param.
        self.i_bone += delta_i_bone
        self.i_axis += delta_i_axis

        # Make sure they are in bounds.
        self.i_bone %= len(self.model.names)
        self.i_axis %= 3 # Flexion, Abduction, Twist.

        self.text_changed()

    def get_mode_text(self):
        # Look up name of the i_bone'th bone.
        bone_name = self.model.names[self.i_bone]
        axis_name = AXIS_NAMES[self.i_axis]
        txt = "Changing bone %s %s\n" % (bone_name, axis_name)
        for i_bone, name in enumerate(self.model.names):
            txt += "%s%s : %.2f, %.2f, %.2f\n" % ((" * " if i_bone == self.i_bone else "   ", name) + tuple(self.model_viewer.pose_params[name]))
        return txt

    def get_text_color(self):
        if self.model.pose_in_theta_space(self.model_viewer.pose_params):
            return (0.0, 0.0, 0.0)
        else:
            return (1.0, 0.0, 0.0)

    def update_angle(self, delta):
        # Look up name of the i_bone'th bone.
        bone_name = self.model.names[self.i_bone]

        # Update the angle for that bone.
        self.model_viewer.pose_params[bone_name][self.i_axis] += delta

        # Put in the range -pi to pi
        self.model_viewer.pose_params[bone_name][self.i_axis] = math.fmod(self.model_viewer.pose_params[bone_name][self.i_axis], 2.0 * math.pi)
        if self.model_viewer.pose_params[bone_name][self.i_axis] < -math.pi: self.model_viewer.pose_params[bone_name][self.i_axis] += 2.0 * math.pi
        if self.model_viewer.pose_params[bone_name][self.i_axis] >  math.pi: self.model_viewer.pose_params[bone_name][self.i_axis] -= 2.0 * math.pi

        self.pose_changed()

class EditGlobalMode(ViewMode):
    def __init__(self, model_viewer, model):
        super(EditGlobalMode, self).__init__(model_viewer, model)

    def get_global_pos_header(self):
        return "Global transform * \n"

    def get_mode_text(self):
        return "Changing global transform"

    def global_transform_modified(self, obj, event):
        self.model_viewer.pose_params['scale'] = np.array(self.model_viewer.mesh_assembly.GetScale())
        self.model_viewer.pose_params['global_translation'] = np.array(self.model_viewer.mesh_assembly.GetPosition())
        axis_angle = self.model_viewer.mesh_assembly.GetOrientationWXYZ()
        self.model_viewer.pose_params['global_rotation'] = np.array(axis_angle[1:4]) * axis_angle[0] * math.pi / 180.0
        self.markers_changed()
        self.text_changed()
        
class EditMarkerMode(ViewMode):
    def __init__(self, model_viewer, model):
        super(EditMarkerMode, self).__init__(model_viewer, model)
        self.i_marker = 0
        self.marker_targets_active = np.zeros(len(self.model.markers), dtype=bool)
        self.marker_target_positions = np.zeros((len(self.model.markers), 3))
        self.marker_ix_dict = {}
        for i, t in enumerate(self.model.markers):
            self.marker_ix_dict[t[0]] = i
            
    def change_marker(self, delta_i_marker):
        self.i_marker += delta_i_marker
        self.i_marker %= len(self.model.markers)
        self.text_changed()

    def get_mode_text(self):
        txt = "Changing marker %s\n" % self.model.markers[self.i_marker][0]
        for i_marker, name_pos in enumerate(self.model.markers):
            name, pos = name_pos
            txt += "%s%s" % (" * " if i_marker == self.i_marker else "   ", name)
            if self.marker_targets_active[i_marker]:
                txt += " : %.2f, %.2f, %.2f" % tuple(self.marker_target_positions[i_marker, :])
            txt += "\n"
        return txt

    def get_active_marker_dict(self):
        marker_names = zip(*self.model.markers)[0]
        active_indices = np.nonzero(self.marker_targets_active)[0]
        return { marker_names[i] : self.marker_target_positions[i, :] for i in active_indices }

    def get_user_marker_list(self):
        user_markers = []
        for index in np.nonzero(self.marker_targets_active)[0]:
            user_markers.append((self.model.markers[index][0], self.marker_target_positions[index, :]))
        return user_markers

    def jump_to_marker(self, marker):
        assert(marker in self.marker_ix_dict)
        self.i_marker = self.marker_ix_dict[marker]
        self.text_changed()

    def reset_markers(self):
        self.marker_targets_active[:] = False

    def set_marker_target(self, position):
        self.marker_target_positions[self.i_marker, :] = position
        self.marker_targets_active[self.i_marker] = True
        self.text_changed()
        self.markers_changed()

    def set_marker_from_model(self):
        self.set_marker_target(self.model_viewer.global_model_marker_array[self.i_marker, :])

    def deactivate_marker(self):
        self.marker_targets_active[self.i_marker] = False
        self.text_changed()
        self.markers_changed()

    def load_markers(self, user_markers):
        self.reset_markers()
        for name, pos in user_markers:
            marker_ix = self.marker_ix_dict[name]
            self.marker_targets_active[marker_ix] = True
            self.marker_target_positions[marker_ix, :] = pos
            
class BoxSelectMode(ViewMode):
    def __init__(self, model_viewer, model):
        super(BoxSelectMode, self).__init__(model_viewer, model)
        self.active_roibox = None

    def box_select_points(self, start_pos, end_pos):
        aspect = self.model_viewer.viewer.renderer.GetAspect()
        frustum_planes = np.zeros(24)
        self.model_viewer.viewer.renderer.GetActiveCamera().GetFrustumPlanes(aspect[0] / aspect[1], frustum_planes)
        min_pos = np.fmin(start_pos, end_pos)
        max_pos = np.fmax(start_pos, end_pos) + 1

        # Shift frustum planes inwards to match the box selection
        y_world_size = 2.0 * self.model_viewer.viewer.renderer.GetActiveCamera().GetParallelScale()
        window_size = self.model_viewer.viewer.renderer.GetSize()
        pixel_to_world_scale = y_world_size / window_size[1]
        frustum_planes[3]  -= pixel_to_world_scale * min_pos[0]
        frustum_planes[7]  -= pixel_to_world_scale * (window_size[0] - max_pos[0])
        frustum_planes[11] -= pixel_to_world_scale * min_pos[1]
        frustum_planes[15] -= pixel_to_world_scale * (window_size[1] - max_pos[1])
        
        # For visualization, it's better to set near and far planes from depth of filtered data
        planes = vtk.vtkPlanes()
        planes.SetFrustumPlanes(frustum_planes)
        self.model_viewer.point_cloud_troupe.set_filtering_frustum(planes)
        filtered_ids = self.model_viewer.point_cloud_troupe.get_filtered_ids()
        if len(filtered_ids) > 0:
            dists = self.model_viewer.cached_points[filtered_ids, :].dot(frustum_planes[16:19])
            min_dist = np.min(dists)
            max_dist = np.max(dists)
            range = max_dist - min_dist
            range = max(range, 0.01)
            frustum_planes[19] = -min_dist + 0.1 * range
            frustum_planes[23] = max_dist + 0.1 * range
            self.set_roibox(frustum_planes)
        else:
            self.reset_roibox()
        # Potential workaround for http://www.vtk.org/Bug/view.php?id=7823
        # self.model_viewer.viewer.renderer.ResetCamera()
        self.model_viewer.change_mode(ViewModes.EDIT_BONES)

    def get_mode_text(self):
        return "Selecting points"

    def reset_roibox(self):
        self.active_roibox = None
        self.model_viewer.set_region_of_interest(self.active_roibox)

    def set_roibox(self, planes_box):
        self.active_roibox = planes_box
        self.model_viewer.set_region_of_interest(self.active_roibox)

class OptimizerMode(ViewMode):
    def __init__(self, model_viewer, model, optimizer):
        super(OptimizerMode, self).__init__(model_viewer, model)
        self.optimizer = optimizer
        if self.optimizer is not None:
            self.optimizer.add_callback(self.optimizer_iteration)
            
    def change_marker_weight(self, mult):
        self.optimizer.options.lambda_target_term_ *= mult
        return self.optimizer.options.lambda_target_term_

    def get_mode_text(self):
        txt = "Optimizing pose\n"
        for i_bone, name in enumerate(self.model.names):
            txt += "   %s : %.2f, %.2f, %.2f\n" % ((name,) + tuple(self.model_viewer.pose_params[name]))
        return txt

    def optimizer_iteration(self, time_in_ms, energy, pose_params, surface_coordinates):
        if time_in_ms > 0:
            self.model_viewer.pose_params = pose_params
            self.pose_changed()

    def optimize_pose(self, points, normals, active_markers):
        if self.optimizer is None: return
        self.optimizer.optimize(self.model_viewer.pose_params, points, normals, active_markers)
        self.pose_changed()

class ViewModes:
    EDIT_BONES = 0
    EDIT_GLOBAL = 1
    EDIT_MARKER = 2
    BOX_SELECT = 3
    OPTIMIZER = 4

class ModelViewer(object):

    def __init__(self, model, optim=None):
        self.model = model
        self.reset_pose_params()
        self._sequence = pose_sequence.PoseSequence()
        self.viewer = ezvtk.vis.Viewer()
        self.view_modes = [ EditBoneMode(self, model),
                            EditGlobalMode(self, model),
                            EditMarkerMode(self, model),
                            BoxSelectMode(self, model),
                            OptimizerMode(self, model, optim) ]

        # Add triangular mesh.
        self.mesh_troupe = ezvtk.troupe.MeshTroupe()
        self.surface_troupe = ezvtk.troupe.LoopSurfaceTroupe(color=SURFACE_COLOUR, opacity=SURFACE_OPACITY)
        self.surface_troupe.set_polygons(model.triangles)
        self.surface_troupe.set_visible(False)
        self.mesh_troupe.set_polygons(model.triangles)
        self.mesh_troupe.set_radius(3.0e-4)
        self.mesh_assembly = vtk.vtkAssembly()
        self.mesh_assembly.AddPart(self.mesh_troupe.actor)
        self.mesh_assembly.AddPart(self.surface_troupe.actor)
        
        # Also add points for easy picking with the mouse.
        self.vertices_troupe = ezvtk.troupe.SpheresTroupe(radius=1e-3)
        colors = np.empty((self.model.n_vertices, 3), dtype=np.uint8)
        colors[:, 0] = 51
        colors[:, 1] = 128
        colors[:, 2] = 179
        for v in PALM_VERTICES:
            colors[v, :] = [ 255, 0, 0 ] # red vertices on palm
        self.vertices_troupe.set_sphere_colors(colors)
        self.mesh_assembly.AddPart(self.vertices_troupe.actor)

        # Markers
        self.markers_troupe = ezvtk.troupe.SpheresTroupe(radius=2e-3, color=MARKER_COLOUR, opacity=0.25)
        self.markers_troupe.set_pickable(False)
        self.mesh_assembly.AddPart(self.markers_troupe.actor)
        self.marker_targets_troupe = ezvtk.troupe.MultipleSphereActorsTroupe(color=MARKER_COLOUR, num_spheres=len(self.model.markers))
        self.marker_targets_troupe.set_pickable(False)
        self.marker_conn_troupe = ezvtk.troupe.TubesTroupe(color=MARKER_COLOUR)
        self.marker_conn_troupe.set_pickable(False)

        # Text troupes 
        self.text_troupe = ezvtk.troupe.TextTroupe()
        self.global_pos_text_troupe = ezvtk.troupe.TextTroupe(relative_position=(1, 1), absolute_offset=(-10, -10))
        self.global_pos_text_troupe.set_alignment('right')
        self.file_name_text_troupe = ezvtk.troupe.TextTroupe(relative_position=(0, 0), absolute_offset=(10, 20))
        
        # Visualize box selection
        self.planes_troupe = ezvtk.troupe.PlanesTroupe(color=(1.0, 0.0, 0.0))

        # Add these to the viewer.
        self.viewer.renderer.AddActor(self.mesh_assembly)
        self.viewer.add_troupes(self.marker_targets_troupe,
                                self.marker_conn_troupe,
                                self.planes_troupe,
                                self.text_troupe,
                                self.global_pos_text_troupe,
                                self.file_name_text_troupe)
        self.point_cloud_troupe = None
        
        # Set up key callbacks
        ensure_mode = lambda m, f : f(self.view_modes[m]) if self.mode == m else self.change_mode(m)
        onlyif_mode = lambda m, f : f(self.view_modes[m]) if self.mode == m else None
        def jumpto_mode(m, f):
            if self.mode != m: self.change_mode(m)
            f(self.view_modes[m])
        self.viewer.add_key_callback('a', lambda : ensure_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.change_i_bone_and_i_axis(m, -1, 0)))
        self.viewer.add_key_callback('z', lambda : ensure_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.change_i_bone_and_i_axis(m, 1, 0)))
        self.viewer.add_key_callback('s', lambda : ensure_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.change_i_bone_and_i_axis(m, 0, 1)))
        self.viewer.add_key_callback('x', lambda : ensure_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.change_i_bone_and_i_axis(m, 0, -1)))
        self.viewer.add_key_callback('d', lambda : onlyif_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.update_angle(m, DELTA)))
        self.viewer.add_key_callback('e', lambda : onlyif_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.update_angle(m, math.pi)))
        self.viewer.add_key_callback('c', lambda : onlyif_mode(ViewModes.EDIT_BONES , lambda m : EditBoneMode.update_angle(m, -DELTA)))
        self.viewer.add_key_callback('f', lambda : ensure_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.change_marker(m, -1)))
        self.viewer.add_key_callback('v', lambda : ensure_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.change_marker(m, 1)))
        self.viewer.add_key_callback('h', lambda : self.change_marker_weight(10))
        self.viewer.add_key_callback('n', lambda : self.change_marker_weight(0.1))
        self.viewer.add_key_callback('1', lambda : jumpto_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.jump_to_marker(m, 'ThumbTip')))
        self.viewer.add_key_callback('2', lambda : jumpto_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.jump_to_marker(m, 'IndexTip')))
        self.viewer.add_key_callback('3', lambda : jumpto_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.jump_to_marker(m, 'MiddleTip')))
        self.viewer.add_key_callback('4', lambda : jumpto_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.jump_to_marker(m, 'RingTip')))
        self.viewer.add_key_callback('5', lambda : jumpto_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.jump_to_marker(m, 'PinkyTip')))
        self.viewer.add_key_callback('r', lambda : onlyif_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.deactivate_marker(m)))
        self.viewer.add_key_callback('u', lambda : onlyif_mode(ViewModes.EDIT_MARKER, lambda m : EditMarkerMode.set_marker_from_model(m)))
        self.viewer.add_key_callback('t', lambda : self.change_mode(ViewModes.EDIT_GLOBAL))
        self.viewer.add_key_callback('o', self.start_optimizer)
        self.viewer.add_key_callback('m', self.toggle_meshview)
        self.viewer.add_key_callback('b', lambda : None if self.point_cloud_troupe is None else self.change_mode(ViewModes.BOX_SELECT))
        self.viewer.add_key_callback('left', lambda : self.change_file(-1))
        self.viewer.add_key_callback('right', lambda : self.change_file(1))
        self.viewer.add_key_callback('i', lambda : self.viewer.pick(False))
        self.viewer.add_key_callback('p', self.save_data)
        self.viewer.add_key_callback('f1', self.show_help)

        # Other callbacks
        self.viewer.add_pick_callback(self.pick)
        self.viewer.add_actor_move_callback(self.view_modes[ViewModes.EDIT_GLOBAL].global_transform_modified)
        self.viewer.add_box_select_callback(self.view_modes[ViewModes.BOX_SELECT].box_select_points)

        # Set initial state
        self.change_mode(ViewModes.EDIT_BONES)
        self.update_mesh()

    @property
    def sequence(self):
        return self._sequence

    @sequence.setter
    def sequence(self, value):
        self.pre_change_file()
        self._sequence = value
        self.post_change_file()

    def show_help(self):
        txt  = "<-/-> : change selected pose file\n"
        txt += "a / z : change selected bone\n"
        txt += "s / x : change selected axis\n"
        txt += "d / c : rotate bone by %.1f radians\n" % DELTA
        txt += "f / v : change selected marker\n"
        txt += "h / n : change optimization weight of user markers\n"
        txt += "1 - 5 : jump to digit tip marker\n"
        txt += "    e : flip bone (rotate by pi)\n"
        txt += "    r : remove current marker\n"
        txt += "    t : edit global transform with mouse\n"
        txt += "    u : update marker position from model\n"
        txt += "    i : query vertex id\n"
        txt += "    o : optimize pose\n"
        txt += "    p : save current pose, markers & ROI box\n"
        txt += "    b : box-select points\n"
        txt += "    m : toggle surface view\n"
        txt += "   F1 : show this help"
        self.text_troupe.set_text(txt)
        self.viewer.render()

    def reset_pose_params(self):
        self.model.reset()
        # Create a dictionary of pose parameters.
        self.pose_params = dict((name, np.asarray([0.0, 0.0, 0.0])) for name in self.model.names)
        self.pose_params['scale'] = np.asarray([1.0, 1.0, 1.0])
        self.pose_params['global_rotation'] = np.asarray([0.0, 0.0, 0.0])
        self.pose_params['global_translation'] = np.asarray([0.0, 0.0, 0.0])

    # Set self.pose_params dict from a pose vector
    def update_pose_params(self, pose):
        # Just for a check - line 4 just contains the number of joints
        assert(pose[3] == [ len(self.model.names) ])
        self.pose_params['scale'] = pose[0]
        self.pose_params['global_rotation'] = pose[1]
        self.pose_params['global_translation'] = pose[2]

        # Update view based on global translation & scale
        self.viewer.set_camera_parallel_view_size(0.2 * np.mean(pose[0]))
        self.viewer.set_camera_focal_point(pose[2])
        
        # Update the pose_params from the flexion and abduction values in the next 22 lines
        for jointId in xrange(NUM_BONES):
            jointName = self.model.names[jointId]
            [scale, flexion, abduction, twist] = pose[jointId + 4]
            self.pose_params[jointName][0] = flexion
            self.pose_params[jointName][1] = abduction  
            self.pose_params[jointName][2] = twist

    def update_point_cloud(self):        
        if not self.sequence.has_point_cloud(): return
        
        # Add point cloud to the viewer
        self.cached_points, self.cached_normals = self.sequence.point_cloud()
        self.point_cloud_troupe = ezvtk.troupe.PointsTroupe()
        self.point_cloud_troupe.set_positions(self.cached_points)
        self.point_cloud_troupe.set_normals(self.cached_normals)
        self.viewer.add_troupes(self.point_cloud_troupe)

    def update_pose(self):
        if self.sequence.has_input_pose_file():
            pose = self.sequence.pose_vector()
        elif self.sequence.has_point_cloud():
            pose = self.sequence.estimate_pose(self.model, self.cached_points)
        else:
            return

        if (pose[0][0] < 0.0):
            self.model.set_mirrored()
            pose[0][0] *= -1.0
        self.update_pose_params(pose)

    # Save the pose_params and marker information to file
    def save_data(self):
        if not self.sequence.has_output_pose_file(): return

        # Make sure root bone rotation is in global transform parameters
        self.model.move_root_bone_rot_to_global(self.pose_params)

        pose = []
        pose.append(np.array(self.pose_params['scale']))
        if self.model.mirrored:
            pose[0][0] *= -1.0
        pose.append(self.pose_params['global_rotation'])
        pose.append(self.pose_params['global_translation'])
        pose.append(np.array([float(NUM_BONES)]))

        # create a pose vector according to the user edits
        for jointId in xrange(NUM_BONES):
            jointName = self.model.names[jointId]
            pose_joint = np.zeros(4)
            pose_joint[0] = 1.0
            # flexion
            pose_joint[1] = self.pose_params[jointName][0]
            # abduction
            pose_joint[2] = self.pose_params[jointName][1]
            # twist. Can be edited for consistency and playing around. In practice leave to 0
            pose_joint[3] = self.pose_params[jointName][2]
            pose.append(pose_joint)

        # Save pose
        self.sequence.save_pose_vector(pose)

        # Markers
        self.update_markers(False)
        self.sequence.save_user_markers(self.view_modes[ViewModes.EDIT_MARKER].get_user_marker_list())
        model_markers = []
        for index, marker in enumerate(self.model.markers):
            model_markers.append((marker[0], self.global_model_marker_array[index, :]))
        self.sequence.save_model_markers(model_markers)

        # Region of interest
        self.sequence.save_roibox(self.view_modes[ViewModes.BOX_SELECT].active_roibox)

        # Update text (because root bone rotation may have been concatenated with global)
        self.update_text_boxes()

    def change_mode(self, mode):
        self.mode = mode
        if self.point_cloud_troupe is not None:
            self.point_cloud_troupe.set_pickable(mode == ViewModes.EDIT_MARKER)
            self.point_cloud_troupe.set_filter_enabled(mode != ViewModes.BOX_SELECT)
        if mode == ViewModes.EDIT_BONES:
            self.viewer.move_camera_mode()
        elif mode == ViewModes.EDIT_GLOBAL:
            self.viewer.move_actor_mode()
        elif mode == ViewModes.EDIT_MARKER:
            self.viewer.mouse_pick_mode()
        elif mode == ViewModes.BOX_SELECT:
            self.viewer.box_select_mode()
            self.viewer.renderer.ResetCameraClippingRange()
        elif mode == ViewModes.OPTIMIZER:
            self.viewer.move_camera_mode()
        self.update_text_boxes()

    def change_marker_weight(self, mult):
        new_weight = self.view_modes[ViewModes.OPTIMIZER].change_marker_weight(mult)
        self.text_troupe.set_text("Marker weight : %f" % new_weight)
        self.viewer.render()

    def start_optimizer(self):
        if self.point_cloud_troupe is None: return
        if self.mode != ViewModes.OPTIMIZER:
            # Make sure root bone rotation is in global transform parameters
            self.model.move_root_bone_rot_to_global(self.pose_params)
            mode_was = self.mode
            self.change_mode(ViewModes.OPTIMIZER)
            active_markers = self.view_modes[ViewModes.EDIT_MARKER].get_active_marker_dict()
            filtered_ids = self.point_cloud_troupe.get_filtered_ids()
            if len(filtered_ids) > MAX_OPT_POINTS:
                filtered_ids = np.random.choice(filtered_ids, MAX_OPT_POINTS, False)
            self.view_modes[ViewModes.OPTIMIZER].optimize_pose(self.cached_points[filtered_ids, :], self.cached_normals[filtered_ids, :], active_markers)
            self.change_mode(mode_was)

    def toggle_meshview(self):
        self.mesh_troupe.toggle_visibility()
        self.surface_troupe.toggle_visibility()
        self.viewer.render()

    def pre_change_file(self):
        self.save_data()
        if self.point_cloud_troupe is not None:
            self.viewer.remove_troupes(self.point_cloud_troupe)
            self.point_cloud_troupe = None
        self.view_modes[ViewModes.BOX_SELECT].reset_roibox()
        self.planes_troupe.set_visible(False)

    def change_file(self, delta_file):
        self.pre_change_file()
        self.sequence.change_file(delta_file)
        self.post_change_file()

    def post_change_file(self):
        self.reset_pose_params()
        self.view_modes[ViewModes.EDIT_MARKER].load_markers(self.sequence.load_user_markers())
        self.update_point_cloud()
        self.update_pose()
        self.file_name_text_troupe.set_text(self.sequence.pose_file_name())
        if (self.sequence.has_roi_box()):
            self.view_modes[ViewModes.BOX_SELECT].set_roibox(self.sequence.load_roibox())
        self.update_mesh()

    def update_markers(self, render=True):
        # Get the posed vertex positions and markers
        vertex_positions = self.model.get_skinned_vertex_positions(self.pose_params, False)
        marker_positions = self.model.get_marker_positions(vertex_positions, self.pose_params, False)
        marker_array = np.empty((len(marker_positions), 3))
        for index, name_pos in enumerate(marker_positions):
            name, pos = name_pos
            marker_array[index, :] = pos

        self.markers_troupe.set_positions(marker_array)
        self.global_model_marker_array = self.model.apply_global_transform(self.pose_params, marker_array)
        self.marker_targets_troupe.set_positions(self.view_modes[ViewModes.EDIT_MARKER].marker_target_positions)
        self.marker_targets_troupe.set_sphere_visibility(self.view_modes[ViewModes.EDIT_MARKER].marker_targets_active)
        self.marker_conn_troupe.set_points(np.vstack((self.global_model_marker_array, self.view_modes[ViewModes.EDIT_MARKER].marker_target_positions)))
        active_targets = np.nonzero(self.view_modes[ViewModes.EDIT_MARKER].marker_targets_active)[0]
        # TubesTroupe doesn't like being given zero-length lines, so remove any zero-length connections
        zero_conns = []
        for ix, i in enumerate(active_targets):
            if np.linalg.norm(self.view_modes[ViewModes.EDIT_MARKER].marker_target_positions[i, :] - self.global_model_marker_array[i, :]) < 1e-6:
                zero_conns.append(ix)
        active_targets = np.delete(active_targets, zero_conns)
        self.marker_conn_troupe.set_start_end_indices(active_targets, np.add(active_targets, len(marker_positions)))

        mean_scale = np.mean(np.fabs(self.pose_params['scale']))
        self.marker_targets_troupe.set_radius(mean_scale * 2e-3)
        self.marker_conn_troupe.set_radius(mean_scale * 6e-4)
        if render: self.viewer.render()
        return vertex_positions

    def update_text_boxes(self, render=True):
        mode_txt = self.view_modes[self.mode].get_mode_text()
        self.text_troupe.set_text(mode_txt)
        self.text_troupe.set_color(*self.view_modes[self.mode].get_text_color())
        
        global_pos_txt = self.view_modes[self.mode].get_global_pos_header()
        scale = self.pose_params['scale'].copy()
        if self.model.mirrored:
            scale[0] *= -1.0
        global_pos_txt +=       "scale : [ %8.2f %8.2f %8.2f ]\n" % tuple(scale)
        global_pos_txt +=    "rotation : [ %8.2f %8.2f %8.2f ]\n" % tuple(self.pose_params['global_rotation'])
        global_pos_txt += "translation : [ %8.2f %8.2f %8.2f ]"   % tuple(self.pose_params['global_translation'])
        self.global_pos_text_troupe.set_text(global_pos_txt)

        if render: self.viewer.render()

    def update_mesh(self):
        self.update_text_boxes(False)
        vertex_positions = self.update_markers(False)

        # Update the positions to the troupes.
        self.vertices_troupe.set_positions(vertex_positions)
        self.mesh_troupe.set_points(vertex_positions)
        self.surface_troupe.set_points(vertex_positions)
        self.mesh_assembly.SetOrientation(0, 0, 0)
        angle = np.linalg.norm(self.pose_params['global_rotation'])
        if angle > 0.0:
            x, y, z = self.pose_params['global_rotation'] / angle
            self.mesh_assembly.RotateWXYZ(angle * 180.0 / math.pi, x, y, z)
        self.mesh_assembly.SetScale(self.pose_params['scale'])
        self.mesh_assembly.SetPosition(self.pose_params['global_translation'])

        # Rerender.
        self.viewer.render()

    def set_region_of_interest(self, planes_vector):
        if planes_vector is None:
            self.planes_troupe.set_visible(False)
            if self.point_cloud_troupe is not None: self.point_cloud_troupe.set_filtering_frustum(None)
        else:
            planes = vtk.vtkPlanes()
            planes.SetFrustumPlanes(planes_vector)
            if self.point_cloud_troupe is not None: self.point_cloud_troupe.set_filtering_frustum(planes)
            self.planes_troupe.set_planes(planes)
            self.planes_troupe.set_visible(True)

    def pick(self, object, event, from_mouse):
        if self.mode == ViewModes.EDIT_MARKER and from_mouse:
            if self.point_cloud_troupe is None: return
            actorCollection = object.GetActors()
            actorCollection.InitTraversal()
            actors = []
            actor = actorCollection.GetNextActor()
            while actor is not None:
                actors.append(actor)
                actor = actorCollection.GetNextActor()
            try:
                pc_ix = next(i for i in xrange(len(actors)) if actors[i] == self.point_cloud_troupe.actor)
                self.view_modes[ViewModes.EDIT_MARKER].set_marker_target(object.GetPickedPositions().GetPoint(pc_ix))
            except StopIteration:
                pass
        else:
            if object.GetAssembly() == self.mesh_assembly:
                path = object.GetPath()
                if path.GetLastNode().GetViewProp() == self.vertices_troupe.actor:
                    i_vertex = self.vertices_troupe.vtk_point_id_to_point_index(self.viewer.cell_picker.GetPointId())
                    self.text_troupe.set_text('Vertex Index is %d' % i_vertex)
            else:
                self.text_troupe.set_text("Move the mouse on top of a vertex and press i to get its index.")
            self.viewer.render()

    def start(self):
        self.viewer.start()


def main():

    # The model 
    model_path = os.path.join(util.get_chira_root(), 'data/models/hand-model-v3/exported_template_from_blender')
    model = load_model(model_path)
    viewer = ModelViewer(model, optimizer.Optimizer(model_path, model))
    viewer.sequence = local_annotation_sequence()
    viewer.start()

if __name__ == '__main__':
    main()
