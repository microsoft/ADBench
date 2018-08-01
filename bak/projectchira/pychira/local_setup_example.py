import os
from pychira import pose_sequence, util

def local_annotation_sequence():
    # Useful directories that should be found on the repo
    captured = os.path.join(util.get_chira_root(), "data/poseprior/trainingData/captured/")
    crafted = os.path.join(util.get_chira_root(), "data/poseprior/trainingData/crafted/")
    fromtests = os.path.join(util.get_chira_root(), "data/poseprior/trainingData/fromTestSuite/")
    samples_from_prior = os.path.join(util.get_chira_root(), 'data/poseprior/trainingData/SamplesFromPrior\\')
    output_path = os.path.join(util.get_chira_root(), "data/poseprior/edited.txt")
        
    def get_files(dir, ext) :
        return [ os.path.join(dir, x) for x in os.listdir(dir) if x.endswith(ext) ]
    
    #viewer.sequence = pose_sequence.FileSequence(get_files(fromtests, '.txt'))
    viewer.sequence = pose_sequence.RecordedSequence("Z:\\Documents\\Chira\\2015-07-06 PM 01-04-22", False)
