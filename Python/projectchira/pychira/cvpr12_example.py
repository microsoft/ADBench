import numpy as np

from pychira.model import Model, load_model, HAND_MODEL_V3_PATH

class Energy(object):

    def __init__(self, model, data_points, correspondences):
        assert isinstance(model, Model)

        self.model = model
        self.data_points = data_points
        self.correspondences = correspondences

        self.n_theta = 6 + 5 * 4


    def to_pose_params(self, theta):
        
        # We need a 3 dimensional rotational parameter for each bone.
        pose_params = {}
        pose_params['global_rotation'] = theta[0:3]
        pose_params['scale'] = np.ones((3,))
        pose_params['global_translation'] = theta[3:6]
        
        for bone_name in self.model.names:
            pose_params[bone_name] = np.zeros((3,))
        
        i_theta = 6 
        # Each finger has rotational degrees of freedom.
        for finger in ["thumb", "index", "middle", "ring", "pinky"]:
            for i in [2, 3, 4]:
                bone_name = finger + str(i)
                # All joints in the finger can flex.
                pose_params[bone_name][0] = theta[i_theta]
                i_theta += 1
                if i == 2:
                    # Only the knuckle can abduct.
                    pose_params[bone_name][1] = theta[i_theta]
                    i_theta += 1

        assert(i_theta == self.n_theta)
        return pose_params

    def evaluate(self, theta):
        assert isinstance(model, Model)

        # Change theta into the pose parameters for the model.
        pose_params = self.to_pose_params(theta)
        
        # Now skin (i.e. pose) the vertices using those parameters.
        vertex_positions = self.model.get_skinned_vertex_positions(pose_params)

        # Now compute the result by adding in squared distance between
        # each data point and it's "corresponding" vertex.
        result = 0.0
        for data_point, i_vertex in zip(self.data_points, self.correspondences):
            result += ((data_point - vertex_positions[i_vertex])**2).sum()

        return result

def save_instance(fn, correspondences, data_points, theta, n_more_vertices = 0):
    fid = open(fn, "w")
    n_pts = data_points.shape[0]
    print("%i %i %i" % (n_pts,theta.size,n_more_vertices) , file = fid)
    for i in range(n_pts):
        print("%i %f %f %f" % (correspondences[i],data_points[i,0],data_points[i,1],data_points[i,2]) , file = fid)
    for t in theta:
        print("%f " % (t) , file = fid)
    fid.close()

## Create Linear blend skinning model.
#model = load_model("../exported_template_from_blender/")

## Construct correspondences and data points.
#n_data_points = 2
#correspondences = np.random.random_integers(0, model.n_vertices - 1, n_data_points)
#data_points = np.zeros((n_data_points, 3))

## Create energy.
#energy = Energy(model, data_points, correspondences)

## Create parameter vector.
#theta = np.random.randn(energy.n_theta)

## Change the energy so that everything is exactly aligned.
#pose_params = energy.to_pose_params(theta)
## Not really useful here, but this shows correct usage of the pose_in_theta_space function
#assert(model.pose_in_theta_space(pose_params))
#vertex_positions = model.get_skinned_vertex_positions(pose_params)
#for i_data_point in range(n_data_points):
#    energy.data_points[i_data_point] = vertex_positions[correspondences[i_data_point]]
#print('Energy with perfect data point correspondences:', energy.evaluate(theta))

## Now add some noise to the data points.
#energy.data_points += .1 * np.random.randn(*energy.data_points.shape)

##save_instance("C:/Users/t-filsra/Workspace/autodiff/hand/instance.txt", correspondences, data_points, theta);

#print('Energy with noisy data points:', energy.evaluate(theta))


#### generate instances ####
init_model = load_model("../exported_template_from_blender/")
n_data_points = [192, 500, 1000, 2000, 4000, 8000, 16000, 32000, 64000, 100000]
n_more_vertices = [0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9456]
data_dir = "C:/Users/t-filsra/Workspace/autodiff/hand_instances/"

for i in range(len(n_data_points)):
    path = data_dir + ("hand%i/" % (i+1))
    model = load_model(path)
    
    correspondences = np.random.random_integers(0, model.n_vertices - 1, n_data_points[i])
    data_points = np.zeros((n_data_points[i], 3))

    energy = Energy(model, data_points, correspondences)

    theta = np.random.randn(energy.n_theta)

    pose_params = energy.to_pose_params(theta)
    vertex_positions = model.get_skinned_vertex_positions(pose_params)
    for i_data_point in range(n_data_points[i]):
        energy.data_points[i_data_point] = vertex_positions[correspondences[i_data_point]]
    print('Energy with perfect data point correspondences:', energy.evaluate(theta))

    # Now add some noise to the data points.
    energy.data_points += .1 * np.random.randn(*energy.data_points.shape)
    print('Energy with noisy data points:', energy.evaluate(theta))
    
    save_instance(path + "instance.txt", correspondences, data_points, theta, n_more_vertices[i]);

