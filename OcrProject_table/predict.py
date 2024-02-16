from PIL import Image
import numpy as np
import cv2
import json
import os
from argparse import ArgumentParser
import math
from typing import Tuple, Union
from deskew import determine_skew
from ultralytics import YOLO
from DocTr import inference


def predict(model, 
            image, 
            img_save_dir='./', 
            img_save_name='test', 
            box_size_up = False,
            box_txt_save_path = 'test.txt',
            ratio = 0.2,
            warpping = False):
    
    """_summary_
    
    This function predicts and crop nutrition table of input image.
    Crop box size can be changed by controlling box_size_up, ratio variables.
    Cropped image is saved in  here : (img_save_dir)/table/(img_save_name)_i
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
    """
    model = YOLO(model)
    #predict using YOLO model
    pred = model.predict(image, imgsz = 1280, conf = 0.5)
    
    i = 0
    # save crop file in 'img_save_dir'/table/'img_save_name'_i
    for pp in pred:
      for p in pp:
        if(box_size_up):
            #save predicted box
            p.save_txt(box_txt_save_path)

            # open file
            f = open(box_txt_save_path, 'r')
            line = f.readline()
            f.close()
            os.remove(box_txt_save_path)
            
            line = line[:-1]
            line = line.split(" ")
            line = np.array(line)
            line=line.astype(float)
            
            #open original image
            #W = img.width
            #H = img.height
            H, W, _  = image.shape
            line[1] = line[1]*W
            line[2] = line[2]*H
            line[3] = line[3]*W
            line[4] = line[4]*H

            #crop and save
            img_cropped = image[(int)(line[2]-line[4]/2*(1+ratio)):(int)(line[2]+line[4]/2*(1+ratio)), (int)(line[1]-line[3]/2*(1+ratio)) : (int)(line[1]+line[3]/2*(1+ratio))]
          
            image_save_path=img_save_dir+'/table/'+img_save_name
            cv2.imwrite(image_save_path+'_'+str(i)+'.jpg', img_cropped )
            #Rotate adopt
            rotated_img = rotate(img_cropped, image_save_path, i)
            
          
        else: 
            #crop and save
            image_save_path=img_save_dir+'/table/'+img_save_name
            p.save_crop(img_save_dir,  img_save_name+'_'+str(i))
            #Rotate adopt
            rotated_img = rotate( image_save_path, i)
           
        if np.any(rotated_img)!= False and warpping:
          
          #Doctr adopt
          warped_img = inference.inference(rotated_img, image_save_path, i)
          
          #Rectangle adopt
          rectangle(warped_img,image_save_path, i )
        else:
          #Rectangle adopt
          rectangle(rotated_img,image_save_path, i )
        
        i=i+1
    return i

def rotate( image, image_save_path,i) :
     
    """_summary_
    
    This function rotates image straight.
    If the angle of inclination is less than 10, do not rotate,
    More than 10, rotation is applied.  
    
    Args:
      image (numpy image): Input image  
      image_save_path (str):  Path to save 
      i (int): Box number detected

    Returns:
        Input image(If image rotation is not required) or Deskew image(if image rotation is required) or False(if there is err)
    """
    
    background=  (0, 0, 0)
    try:
        
      h, w, _ = image.shape
      size_changed=0
      if h < 600 and w < 600 :#size up to small size 
        image = cv2.resize(image, (w*2, h*2), interpolation=cv2.INTER_LINEAR)
        size_changed = 1
      grayscale = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
      angle = determine_skew(grayscale)
      if size_changed:#restoring size
        image = cv2.resize(image, (w, h), interpolation=cv2.INTER_LINEAR)

      if (angle<3 and angle>-3) or angle>25 or angle<-25:#temporary 10 -> can be changed
        image = cv2.resize(image, (w, h), interpolation=cv2.INTER_LINEAR)
        print(str(i)+" is straight, Rotated is not applied")
        return image
      
      old_width, old_height = image.shape[:2]
      angle_radian = math.radians(angle)
      width = abs(np.sin(angle_radian) * old_height) + abs(np.cos(angle_radian) * old_width)
      height = abs(np.sin(angle_radian) * old_width) + abs(np.cos(angle_radian) * old_height)

      image_center = tuple(np.array(image.shape[1::-1]) / 2)
      rot_mat = cv2.getRotationMatrix2D(image_center, angle, 1.0)
      rot_mat[1, 2] += (width - old_width) / 2
      rot_mat[0, 2] += (height - old_height) / 2

      #rotate image
      deskew_image = cv2.warpAffine(image, rot_mat, (int(round(height)), int(round(width))), borderValue=background)
      
      #save
      cv2.imwrite(image_save_path+'_deskew_'+ str(i)+'.jpg', deskew_image)


    except:
      print("No crop image. Please check file path.")
      return False
    return deskew_image
    




def rectangle(img,
              img_save_path,
              i
              ):
    
    """_summary_
    
    This functon makes cropped image to rectangular image.
    Changed image is saved in the same path of cropped image. 
    So, original cropped image is changed and cannot undo the process.
    Original image's height and width info is saved in json format file. 
    
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

    Args:
        image (numpy image): Input image 
        img_save_path (str): give one of cropped images' path. 
        i (int): # of cropped image of input. Defaults to 0.
    Returns:
        bool: True if processed correctly. If False, there is no sufficient files to convert. 
    """
    width = 1280
    height = 1280
    minsize = min(width, height)
    
    json_write = {}
    json_write["shape"] = []
    
     

    try:
      img_height, img_width, _ =img.shape 
      
      #img processing
      resize_mag = minsize / max(img_width, img_height)
      resize_width = (int)(img_width * resize_mag)
      resize_height = (int)(img_height * resize_mag)

      img_resize = cv2.resize(img, (resize_width, resize_height), interpolation=cv2.INTER_LINEAR)
      
      img_out = np.ones((height, width, 3), dtype=np.uint8) * 255
      
      x_offset = (width - resize_width) // 2
      y_offset = (height - resize_height) // 2
      img_out[y_offset:y_offset+resize_height, x_offset:x_offset+resize_width] = img_resize
      
      cv2.imwrite(img_save_path+'_rec_'+str(i)+'.jpg', img_out)
      
      shape = {
          "path": img_save_path+'_'+str(i)+'.jpg',
          "H": img_height,
          "W": img_width
      }
      json_write["shape"].append(shape)
    
    except:
      print("No crop image. Please check file path.")
      return False
    
    with open(img_save_path+'_'+str(i)+'.json', 'w') as outfile:
        json.dump(json_write, outfile, indent=4)
    
    return True


if __name__ == "__main__":

  parser = ArgumentParser(description="table detection parameters")
  
  parser.add_argument('-m', '--model', type=str, required = True)
  parser.add_argument('-i', '--input', type=str, required = True )
  parser.add_argument('--img_save_dir', type=str, default='./')
  parser.add_argument('--img_save_name', type=str, default='test')
  parser.add_argument("--box_size_up", type=bool, default=False)
  parser.add_argument("--box_txt_save_path", type=str, default='test.txt')
  parser.add_argument('-r', "--ratio", type=float, default=0.2)
  parser.add_argument('-w', "--warpping", type=bool, default=False)

  args = parser.parse_args()

  image = cv2.imread(args.input)

  pred = predict(args.model, 
          image, 
          args.img_save_dir, 
          args.img_save_name, 
          args.box_size_up ,
          args.box_txt_save_path,
          args.ratio ,
          args.warpping
          )
  if pred==0 :
    print("No predicted table, Please check input image")
  

    # All done
    print("\nTable detection complete.")