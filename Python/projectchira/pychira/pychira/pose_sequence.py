from pychira import ply_reader, util
from rotation import *
import numpy as np
import os

util.add_boost_python_to_dll_path()
import pychira.recordings

NUM_BONES = 22

def pca(pos):
    mean = np.mean(pos, axis=0)
    zeroed_pos = pos - mean.T
    [evals, evecs] = np.linalg.eigh(np.cov(zeroed_pos.T))
    sortixs = evals.argsort()
    return mean, np.sqrt(evals[sortixs]), evecs[:, sortixs]

def estimate_pose_vector_from_points(hand_model, positions):
    mean_point, evals_point, evecs_point = pca(positions)
    mean_model, evals_model, evecs_model = pca(hand_model.base_positions)
    global_scale = evals_point[2] / evals_model[2]

    # Ensure both sets of eigenvectors have the same handedness
    det_point = np.linalg.det(evecs_point)
    det_model = np.linalg.det(evecs_model)
    if det_point * det_model < 0.0:
        evecs_point[:, 2] *= -1.0

    # Rotation matrix that aligns the principal directions
    R = np.matrix(evecs_point) * np.transpose(np.matrix(evecs_model))
    
    # Build up pose vector
    pose = []
    pose.append(np.ones(3) * global_scale)        # scale
    pose.append(rotation_matrix_to_axis_angle(R)) # rotation
    # Don't subtract the mean vertex position from the model; using the origin gives a better estimate for now
    pose.append(mean_point)                       # translation
    pose.append(np.array([float(NUM_BONES)]))
    for i in xrange(NUM_BONES):
        pose.append(np.array([ 1.0, 0.0, 0.0, 0.0 ]))
    return pose

class PoseSequence(object):
    def change_file(self, delta_file):
        pass

    def has_point_cloud(self):
        return False
    
    def has_input_pose_file(self):
        return os.path.isfile(self.pose_file_name())
    
    def has_roi_box(self):
        return os.path.isfile(self.roi_box_file_name())

    def has_output_pose_file(self):
        return len(self.pose_file_name()) > 0

    def pose_file_name(self):
        return ""

    def base_file_name(self):
        pose_file = self.pose_file_name()
        if (pose_file.endswith(".txt")): pose_file = pose_file[:-4]
        if (pose_file.endswith("_pose")): pose_file = pose_file[:-5]
        return pose_file

    def model_marker_file_name(self):
        return self.base_file_name() + "_model_markers.txt"

    def roi_box_file_name(self):
        return self.base_file_name() + "_roi_box.txt"

    def user_marker_file_name(self):
        return self.base_file_name() + "_user_markers.txt"

    # Get a pose file as a list with
    # 3 vectors of size 3 for: scale, rotation, translation
    # 1 number of joints (for now always 22, i.e. len(self.model.names))
    # 22 vectors of dim 4 (scale, flexion, abduction, twist), for each join in the order given by self.model.names
    def pose_vector(self):
        assert(self.has_input_pose_file())
        def gen():
            with open(self.pose_file_name()) as f:        
                lines = f.readlines()
                def read(l, count): 
                    bits = lines[l].replace('\n', '').split(' ')
                    return np.array([ float(bits[i]) for i in xrange(count) ])

                # scale, rotation, translation
                for i in xrange(3) : yield read(i, 3) 
                # linecount
                yield read(3, 1)
                # Update the pose_params from the flexion and abduction values in the next 22 lines
                for jointId in xrange(NUM_BONES): yield read(jointId + 4, 4)
        return [ x for x in gen() ]

    # Save to txt file a pose array that has the representation above
    def save_pose_vector(self, pose):
        with open(self.pose_file_name(), 'w') as f:
            for line in pose: 
                strip = lambda(x): x[0: len(x) - 2] if x.endswith('.0') else x[0: len(x) - 1] if x.endswith('.') else x
                f.writelines(' '.join(strip(str(x)) for x in line) + '\n')

    def load_user_markers(self):
        markers = []
        file_name = self.user_marker_file_name()
        if not os.path.isfile(file_name): return markers
        with open(file_name) as f:
            for line in f.readlines():
                tokens = line.replace('\n', '').split(':')
                markers.append((tokens[0], np.array([float(t) for t in tokens[1:]])))
        return markers

    def save_markers(self, file_name, markers):
        if len(markers) == 0:
            if os.path.isfile(file_name):
                os.unlink(file_name)
            return
        with open(file_name, 'w') as f:
            for name, pos in markers:
                f.writelines(name + ':' + ':'.join([str(p) for p in pos]) + '\n')

    def save_model_markers(self, model_markers):
        self.save_markers(self.model_marker_file_name(), model_markers)

    def save_user_markers(self, user_markers):
        self.save_markers(self.user_marker_file_name(), user_markers)

    def load_roibox(self):
        return np.fromfile(self.roi_box_file_name(), sep=' ')

    def save_roibox(self, roibox):
        file_name = self.roi_box_file_name()
        if roibox is None:
            if os.path.isfile(file_name):
                os.unlink(file_name)
        else:
            roibox.tofile(file_name, ' ')
        
class PoseFile(object):
    def __init__(self, pose_file, ply_file=None):
        self.pose_file = pose_file
        self.ply_file = ply_file

    def has_point_cloud(self):
        if self.ply_file is None: return False
        return os.path.isfile(self.ply_file)

class FileSequence(PoseSequence):
    def __init__(self, output_pose_files, ply_files=[]):
        self.files = []
        assert(len(output_pose_files) > 0)
        for pose, ply in map(None, output_pose_files, ply_files):
            self.files.append(PoseFile(pose, ply))
        self.file_num = 0

    def change_file(self, delta_file):
        self.file_num += delta_file
        self.file_num %= len(self.files)

    def has_point_cloud(self):
        return self.files[self.file_num].has_point_cloud()

    def estimate_pose(self, model, positions):
        return estimate_pose_vector_from_points(model, positions)

    def point_cloud(self):
        assert(self.has_point_cloud())
        point_cloud_file = self.files[self.file_num].ply_file
        return ply_reader.read_ply_point_cloud(point_cloud_file)

    def pose_file_name(self):
        return self.files[self.file_num].pose_file

class RecordedSequence(PoseSequence):
    def __init__(self, seqname, from_repo):
        self.rs = pychira.recordings.RecordedSequence(seqname, from_repo)
        self.frame_num = 0
        self.previous_pose = None
        self.previous_roibox = None

    def change_file(self, delta_file):
        self.frame_num += delta_file
        self.frame_num %= self.rs.frame_count

    def has_point_cloud(self):
        return True

    def has_roi_box(self):
        return self.previous_roibox is not None or super(RecordedSequence, self).has_roi_box()

    def estimate_pose(self, model, positions):
        if self.previous_pose is None:
            # TODO: improve estimate
            pose_vec = estimate_pose_vector_from_points(model, positions)
            # Overwrite scale estimate
            pose_vec[0] = np.ones(3)
            return pose_vec
        else:
            # RecordedSequence is assumed to be tracking, so previous pose is a good estimate for a neighbouring frame
            return self.previous_pose

    def point_cloud(self):
        assert(self.has_point_cloud())
        points = self.rs.get_world_points(self.frame_num)
        points.shape = (points.shape[0] * points.shape[1], 3)
        normals = self.rs.get_world_normals(self.frame_num)
        normals.shape = (normals.shape[0] * normals.shape[1], 3)
        return points, normals

    def pose_file_name(self):
        depth_name = self.rs.get_depth_file_name(self.frame_num)
        assert(depth_name.endswith("_depth.png"))
        return self.rs.sequence_root + depth_name[:-10] + "_pose.txt"

    def save_pose_vector(self, pose):
        self.previous_pose = pose
        super(RecordedSequence, self).save_pose_vector(pose)

    def load_roibox(self):
        if super(RecordedSequence, self).has_roi_box():
            return super(RecordedSequence, self).load_roibox()
        else:
            assert(self.previous_roibox is not None)
            return self.previous_roibox

    def save_roibox(self, roibox):
        self.previous_roibox = roibox
        super(RecordedSequence, self).save_roibox(roibox)
