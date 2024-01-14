from PIL import Image
import numpy as np
import json
import os

def predict(model, 
            input, 
            img_save_dir='./', 
            img_save_name='./test', 
            box_size_up = False,
            box_txt_save_path = './test.txt',
            ratio = 0.2
            ):
    
    """_summary_
    
    This function predicts and crop nutrition table of input image.
    Crop box size can be changed by controlling box_size_up, ratio variables.
    Cropped image is saved in  here : (img_save_dir)/table/(img_save_name)_i
    This path can be changes by modifying the codes below.
    
    Args:
        model (yolo model): YOLO model
        input (str): input image path. EX) 'dir/name.jpg'
        img_save_dir (str, optional):  Defaults to './'.
        img_save_name (str, optional): Defaults to './test'.
        box_size_up (bool, optional):  True if use DocTr and need crop box size up. Defaults to False.
        box_txt_save_path (str, optional): optinally needed when box_size_up is True. Defaults to './test.txt'.
        ratio (float, optional): box size up ratio. Defaults to 0.2.

    Returns:
        i (int): # of cropped image of input. typically one, but can be more if model predicts multiple tables.
    """
    
    #predict using YOLO model
    pred = model.predict(input, imgsz = 1280, conf = 0.5)
    
    
    i = 0
    # save crop file in 'img_save_dir'/table/'img_save_name'_i
    for p in pred:
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
            img = Image.open(input)
            W = img.width
            H = img.height

            line[1] = line[1]*W
            line[2] = line[2]*H
            line[3] = line[3]*W
            line[4] = line[4]*H

            #crop and save
            img_cropped = img.crop((line[1]-line[3]/2*(1+ratio), line[2]-line[4]/2*(1+ratio), line[1]+line[3]/2*(1+ratio), line[2]+line[4]/2*(1+ratio)))
            img_cropped.save(img_save_dir+'table/'+img_save_name+'_'+str(i)+'.jpg')
            
        else: 
            p.save_crop(img_save_dir, img_save_name+'_'+str(i))
        
        i=i+1
        
    return i

def rectangle(i = 0, 
              img_save_path='./test_0.jpg', 
              json_path = './test.json'
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
        i (int, optional): # of cropped image of input. Defaults to 0.
        img_save_path (str, optional): give one of cropped images' path.  Defaults to './test_0.jpg'.
        json_path (str, optional): height and width of images are saved in this file. Defaults to './test.json'.
        
    Returns:
        bool: True if processed correctly. If False, there is no sufficient files to convert. 
    """
    
    width = 1280
    height = 1280
    minsize = min(width, height)
    
    json_write = {}
    json_write["shape"] = []
    
    for j in range(i):
        addr = img_save_path[:-5]+str(j)+'.jpg'    

        try:
            img = Image.open(addr)
            
            #img processing
            resize_mag = minsize / max(img.width, img.height)
            resize_width = (int)(img.width * resize_mag)
            resize_height = (int)(img.height * resize_mag)

            img_resize = img.resize((resize_width,resize_height))
            
            img_out = Image.new('RGB', (width,height),(255,255,255)) # white : (255,255,255)
            img_out.paste(img_resize, ((int)((width - img_resize.width)/2), (int)((height - img_resize.height)/2)))
            img_out.save(addr)
            
            
            #for json file
            np_img = np.array(img)
            
            shape = {
                "path": addr,
                "H": np_img.shape[0],
                "W": np_img.shape[1]
            }
            json_write["shape"].append(shape)
            
        except:
          print("No crop image. Please check file path.")
          return False

    with open(json_path, 'w') as outfile:
        json.dump(json_write, outfile, indent=4)
    
    return True
          