import cv2
from skimage import img_as_ubyte, img_as_float32
import numpy as np
import json
from tqdm import tqdm
import torch


if __name__ == '__main__':
    kpdetector_modelpath = "mobile_models\kp_detector.pt"
    generator_modelpath = "mobile_models\generator.pt"

    img_path = r"test_images\male_std.jpg"
    driving_kp_path = r'support_materials\myh-389-fps15.json'
    save_video_folder = r'results'

    # load pytorch mobile model, kp
    kp_detector = torch.jit.load(kpdetector_modelpath) # load kp_detector pytorch mobile model
    generator = torch.jit.load(generator_modelpath) # load generator pytorch mobile model
    with open(driving_kp_path) as f:
        driving_motion_kp = json.load(f) # load driving_motion_kp
    print("loading materials ... finished.")

    # run kp_detector on image
    img = cv2.cvtColor(cv2.imread(img_path), cv2.COLOR_BGR2RGB) # read and convert to RGB
    img = img_as_float32(cv2.resize(img, (256, 256))) # resize to (256,256,3)
    img = torch.tensor(img[np.newaxis].astype(np.float32)).permute(0, 3, 1, 2) # reshape to (1,3,256,256)
    kp_source = kp_detector(img) # kp_source shape = 'value': (1,10,2), 'jacobian':(1,10,2,2)
    print("run kp_detector on image ... finished.")

    # make animation
    predictions = []
    for kp_driving_flat in tqdm(driving_motion_kp):

        # reshape kp['value]: (10,2) -> (1,10,2)
        val = np.array(kp_driving_flat['value'], dtype=np.float32)
        val = torch.tensor(val[np.newaxis].astype(np.float32))

        # reshape kp['value]: (1,10,2,2) -> (1,10,2,2)
        jac = np.array(kp_driving_flat['jacobian'], dtype=np.float32)
        jac = torch.tensor(jac[np.newaxis].astype(np.float32))

        # make prediction for each frame
        kp_driving = {'value':val, 'jacobian':jac}
        res = generator(img, kp_driving, kp_source)
        predictions.append(res['prediction']) # res['prediction'].shape = (1,3,256,256)
    print("make animation ... finished.")


