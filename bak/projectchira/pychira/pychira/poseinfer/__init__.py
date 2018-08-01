from _poseinfer import *
import numpy as np
       
def update_pose_dict_from_obj(py_model, pose_params_dict, pose_params_obj):
    pose_params_dict['scale'] = pose_params_obj.global_scale.astype(np.float64)
    pose_params_dict['global_rotation'] = pose_params_obj.global_rotation.astype(np.float64)
    pose_params_dict['global_translation'] = pose_params_obj.global_translation.astype(np.float64)
    for i, name in enumerate(py_model.names):
        pose_params_dict[name] = pose_params_obj.get_joint_rotation(i).astype(np.float64)

def update_pose_obj_from_dict(py_model, pose_params_dict, pose_params_obj):
    pose_params_obj.global_scale = pose_params_dict['scale'].astype(np.float32)
    pose_params_obj.global_rotation = pose_params_dict['global_rotation'].astype(np.float32)
    pose_params_obj.global_translation = pose_params_dict['global_translation'].astype(np.float32)
    for i, name in enumerate(py_model.names):
        pose_params_obj.set_joint_rotation(i, pose_params_dict[name].astype(np.float32))