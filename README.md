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
```

#### predict
This function predicts and crop nutrition table of input image.
Crop box size can be changed by controlling box_size_up, ratio variables.
Cropped image is saved in  here : (img_save_dir)/table/(img_save_name)_i
This path can be changes by modifying the codes below.
    
Args:
- model (yolo model): YOLO model
- input (str): input image path. EX) 'dir/name.jpg'
- img_save_dir (str, optional):  Defaults to './'.
- img_save_name (str, optional): Defaults to './test'.
- box_size_up (bool, optional):  True if use DocTr and need crop box size up. Defaults to False.
- box_txt_save_path (str, optional): optinally needed when box_size_up is True. Defaults to './test.txt'.
- ratio (float, optional): box size up ratio. Defaults to 0.2.

Returns:
- i (int): # of cropped image of input. typically one, but can be more if model predicts multiple tables.
  
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
- i (int, optional): # of cropped image of input. Defaults to 0.
- img_save_path (str, optional): give one of cropped images' path.  Defaults to './test_0.jpg'.
- json_path (str, optional): height and width of images are saved in this file. Defaults to './test.json'.
        
Returns:
- bool: True if processed correctly. If False, there is no sufficient files to convert. 
