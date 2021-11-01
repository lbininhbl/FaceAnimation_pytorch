from argparse import ArgumentParser
import imageio
from PIL import Image
from tqdm import tqdm

from scipy.spatial import ConvexHull
import numpy as np

import coremltools as ct

import matplotlib.pyplot as plt

# output nodes in CoreML model
VAL_ALIAS = 'var_452' # value in kp_detector output, shape (1,10,2)
JAC_ALIAS = 'var_489' # jacobian in kp_detector output, shape(1,10,2,2)
IMG_ALIAS = 'var_1593' # predicted image in generator output, shape (1,3,256,256)
NORM_VAL_ALIAS = 'var_9' # normalized kp value in kp_processor output, shape (1,10,2)
NORM_JAC_ALIAS = 'var_147' # normalized kp value in kp_processor output, shape(1,10,2,2)


def align_image(img, std_face_path='male_std.jpg'):
#    from face_utils import get_lms, to_dlib_68landmarks

    def get_image_landmark(img):
        lm = get_lms(img)[0]
        lm = to_dlib_68landmarks(lm)
        return lm

    # read standard face and get landmarks
    std_face = cv2.cvtColor(cv2.imread(std_face_path), cv2.COLOR_BGR2RGB)
    lm_std = get_image_landmark(std_face)
    _h, _w = std_face.shape[:2]

    # read source image and get landmarks
    # lm = get_image_landmark(img)
    lm = get_lms(img)
    if len(lm)>1:
        print('Multiple face detected. But take only 1 for animation.')
    lm = lm[0]
    lm = to_dlib_68landmarks(lm)
    trans_mat = cv2.estimateAffinePartial2D(lm, lm_std)[0]

    # warp source image according to standard face
    img_T = cv2.warpAffine(img, trans_mat, (_w, _h), flags=cv2.INTER_CUBIC)
    img_T = cv2.resize(img_T, (256, 256))

    return img_T, trans_mat, std_face.shape


def make_animation(source_image, driving_video, generator, kp_detector, kp_processor):

    predictions = []


    kp_source = kp_detector.predict({'image_0': source_image})
    kp_driving_initial = kp_detector.predict({'image_0': driving_video[0]})

    for driving_frame in tqdm(driving_video):
        kp_driving = kp_detector.predict({'image_0': driving_frame})

        kp_norm = kp_processor.predict({'kp_drv_val': kp_driving[VAL_ALIAS],
                                        'kp_drv_jac': kp_driving[JAC_ALIAS],
                                        'kp_drv_init_val': kp_driving_initial[VAL_ALIAS],
                                        'kp_drv_init_jac': kp_driving_initial[JAC_ALIAS],
                                        'kp_src_val': kp_source[VAL_ALIAS],
                                        'kp_src_jac': kp_source[JAC_ALIAS]})

        out = generator.predict({'image_0': source_image,
                                 'kp_drv_val': kp_norm[NORM_VAL_ALIAS],
                                 'kp_drv_jac': kp_norm[NORM_JAC_ALIAS],
                                 'kp_src_val': kp_source[VAL_ALIAS],
                                 'kp_src_jac': kp_source[JAC_ALIAS]})

        predictions.append(np.transpose(out[IMG_ALIAS], [0, 2, 3, 1])[0])
    return predictions


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument("--kpdetector", default='coreml_model/models/kpdetector-NormInput.mlmodel')
    parser.add_argument("--generator", default='coreml_model/models/generator-NormInput.mlmodel')
    parser.add_argument("--kpprocessor", default='coreml_model/models/kpprocessor.mlmodel')

    parser.add_argument("--source_image", default='pytorch_model/test_images/male_std.jpg')
#    parser.add_argument("--source_image", default='test_images/laotou.png')
    parser.add_argument("--driving_video", default='pytorch_model/video_aligned/myh_fps_down.mp4')
    parser.add_argument("--result_video", default='result.mp4')

    opt = parser.parse_args()

    # read inputs
    source_image = Image.open(opt.source_image)
    source_image = source_image.resize((256,256), Image.ANTIALIAS)

    reader = imageio.get_reader(opt.driving_video)
    fps = reader.get_meta_data()['fps']
    driving_video = []
    try:
        for im in reader:
            # CoreML model in python requires PIL image object
            driving_video.append(Image.fromarray(im))
    except RuntimeError:
        pass
    reader.close()

    # align and crop image
    # source_image_T, trans_mat, std_shape = align_image(source_image)

    # load CoreML models
    kp_detector = ct.models.MLModel(opt.kpdetector)
    generator = ct.models.MLModel(opt.generator)
    kp_processor = ct.models.MLModel(opt.kpprocessor)
    print('Model loaded.')

    # make animation
    predictions = make_animation(source_image, driving_video,
                                 generator, kp_detector, kp_processor)
    print('Animation finished.')

    # restore and save video
    writer = imageio.get_writer(opt.result_video, fps=fps)
    for pred in predictions:
        frame = (pred*255).astype(np.uint8) # restore
        writer.append_data(frame) # save
    writer.close()
    print('Result video saved at %s' % opt.result_video)
