
# OCR_Project
Prometheus Deep-Learning OCR Porject

## Table Detection
### table_detection
Can be used like this.
```
!pip install ultralytics
from ultralytics import YOLO

%load_ext autoreload #colab
%autoreload 2 #colab

from table_detection import *

model = YOLO('/content/drive/MyDrive/yolo_re/100ep/best.pt')  # load a custom model

i= predict(model, '/content/KakaoTalk_20231120_024232761_26.jpg', img_save_name = 'test2')
rectangle(i, '/content/table/test2_0.jpg')

+
- !pip install timm
- !pip install deskew
* In DocTr/inference.py -> def inference() : there are model paths required for Doctor.
please edit it to your location Absolute path. (the models are in DocTr/model_pretrained/)
```

#### predict
This function predicts and crop nutrition table of input image.
Crop box size can be changed by controlling box_size_up, ratio variables.
Cropped image is saved in  here : `(img_save_dir)/table/(img_save_name)_i`
This path can be changes by modifying the codes below.
    

Args:
  model (yolo model): YOLO model
  img (numpy image): input image  
  img_save_dir (str, optional):  Defaults to './'.
  img_save_name (str, optional): Defaults to './test'.
  box_size_up (bool, optional):  True if use DocTr and need crop box size up. Defaults to False.
  box_txt_save_path (str, optional): optinally needed when box_size_up is True. Defaults to './test.txt'.
  ratio (float, optional): box size up ratio. Defaults to 0.2.

Returns:
    i (int): # of cropped image of input. typically one, but can be more if model predicts multiple tables.

### rotate
This function rotates image straight.
If the angle of inclination is less than 10, do not rotate,
But if it is more than 10, rotation is applied.  
    
Args: 
- image (numpy image): Input image  
- image_save_path (str):  Path to save 
- i (int): Box number detected

Returns:
- Input image(If image rotation is not required) or Deskew image(if image rotation is required) or False(if there is err)

### warpping
This function unfolds crumpled or round-shaped image.
* Use "DocTr" git (https://github.com/fh2019ustc/DocTr.git)
  
#### rectangle
This functon makes cropped image to rectangular image.
Changed image is saved in the same path of cropped image. 
So, original cropped image is changed and cannot undo the process.
Original image's height and width info is saved in json format file. 
```
    json file example:
    {
        "shape": [
            {
                "path": "/content/table/test_0.jpg",
                "H": 1280,
                "W": 1280
            }
        ]
    }
```
Args:
- image (numpy image): Input image
- img_save_path (str): give one of cropped images' path.  Defaults to './test_0.jpg'.
- i (int): # of cropped image of input. Defaults to 0.
Returns:
    bool: True if processed correctly. If False, there is no sufficient files to convert. 
=======

---
# APP
- Front-End : Flutter
- Back-End : Flask

## ocr front

### Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 294fa78 (app)
## Backend

### Installation

```
pip install opencv-python 
pip install flask 
pip install tensorflow 
pip install pillow 
pip install --upgrade Werkzeug
pip install flask_cors 
pip install Flask-Reuploaded
pip install ultralytics 
pip install timm 
pip install deskew 
pip install opencv-contrib-python
pip install --upgrade google-cloud-vision google-auth
```

