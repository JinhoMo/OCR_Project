import os
import io
import numpy as np
import platform
from PIL import ImageFont, ImageDraw, Image
from matplotlib import pyplot as plt
import cv2
from google.cloud import vision
import difflib
from PIL import Image
import json
from argparse import ArgumentParser
import math
from typing import Tuple, Union
from deskew import determine_skew
from ultralytics import YOLO
from os import path
import re
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
from flask_cors import CORS
from flask_uploads import UploadSet, configure_uploads, IMAGES
import base64
from PIL import Image


# Set environment variable about google vision
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] ="./ocrproject-413810-c037869d3d00.json"

client_options = {'api_endpoint': 'eu-vision.googleapis.com'}
client = vision.ImageAnnotatorClient(client_options=client_options)
# flask sertver setting
app = Flask(__name__)
CORS(app)

# Set up image uploads
app.config["UPLOAD_FOLDER"] = "uploads"
app.config["ALLOWED_EXTENSIONS"] = {'png', 'jpg', 'jpeg', 'gif'}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
def predict(image):
    
    model = "./best.pt"#
    model = YOLO(model)
    #predict using YOLO model
    pred = model.predict(image, imgsz = 1280, conf = 0.5)
    background=  (255, 255, 255)
    ratio = 0.2
    img_out = [False]# retrun false
    # save crop file in 'img_save_dir'/table/'img_save_name'_i
    for pp in pred:
      for p in pp:
        #save predicted box
        line = np.array(p.boxes.xywhn.detach().cpu())[0]
        #open original image
        #W = img.width
        #H = img.height
        H, W, _  = image.shape
        print("image.shape",image.shape)
        line[0] = line[0]*W
        line[1] = line[1]*H
        line[2] = line[2]*W
        line[3] = line[3]*H

        #crop and save
        img_cropped = image[(int)(line[1]-line[3]/2*(1+ratio)):(int)(line[1]+line[3]/2*(1+ratio)), (int)(line[0]-line[2]/2*(1+ratio)) : (int)(line[0]+line[2]/2*(1+ratio))]
        print("img_cropped",img_cropped,type(img_cropped),img_cropped.shape)
        #Rotate adopt   
        h, w, _ = img_cropped.shape
        size_changed=0
        if h==0 or w==0 or h<30 or w<30 : # 
            continue
        if  h < 600 and  w < 600 :#size up to small size 
            img_cropped = cv2.resize(img_cropped, (w*2, h*2), interpolation=cv2.INTER_LINEAR)
            size_changed = 1
        grayscale = cv2.cvtColor(img_cropped, cv2.COLOR_BGR2GRAY)
        # print("grayscale:",grayscale, grayscale.shape)
        angle = determine_skew(grayscale)
        # print("angle", angle)
        if size_changed:#restoring size
            img_cropped = cv2.resize(img_cropped, (w, h), interpolation=cv2.INTER_LINEAR)

        if (angle<3 and angle>-3) or angle>25 or angle<-25:# -3<temporary<3 or temporary<-25 or temporary>25 -> can be changed
            deskew_image = img_cropped
        else:
            old_width, old_height = img_cropped.shape[:2]
            angle_radian = math.radians(angle)
            width = abs(np.sin(angle_radian) * old_height) + abs(np.cos(angle_radian) * old_width)
            height = abs(np.sin(angle_radian) * old_width) + abs(np.cos(angle_radian) * old_height)

            image_center = tuple(np.array(img_cropped.shape[1::-1]) / 2)
            rot_mat = cv2.getRotationMatrix2D(image_center, angle, 1.0)
            rot_mat[1, 2] += (width - old_width) / 2
            rot_mat[0, 2] += (height - old_height) / 2

            #rotate image
            deskew_image = cv2.warpAffine(img_cropped, rot_mat, (int(round(height)), int(round(width))), borderValue=background)
        
        #img processing
        width = 1280
        height = 1280
        minsize = min(width, height)
        """
        json_write = {}
        json_write["shape"] = []
        """
        img_height, img_width, _ =deskew_image.shape 
        
        
        resize_mag = minsize / max(img_width, img_height)
        resize_width = (int)(img_width * resize_mag)
        resize_height = (int)(img_height * resize_mag)

        img_resize = cv2.resize(deskew_image, (resize_width, resize_height), interpolation=cv2.INTER_LINEAR)
        
        img_out = np.ones((height, width, 3), dtype=np.uint8) * 255
        
        x_offset = (width - resize_width) // 2
        y_offset = (height - resize_height) // 2
        img_out[y_offset:y_offset+resize_height, x_offset:x_offset+resize_width] = img_resize
        """
        shape = {
            "path": img_save_path+'_'+str(i)+'.jpg',
            "H": img_height,
            "W": img_width
        }
        """
        return img_out
    return img_out

def extract_english_strings(text):
  # this function retunes only english text, in lower alphabet in list format (number is not included)
    english_pattern = re.compile('[A-Za-z]+')
    english_strings = english_pattern.findall(text.lower())
    return english_strings

def extract_numbers(text):
  # this function returns only numbers in text, convert it float type, list format

  # 1. float type value extract
    number_pattern_f = re.compile(r"\d+\.\d+") 
    numbers_f = number_pattern_f.findall(text)
    
    new_text = text
    for i in numbers_f:
        new_text = new_text.replace(i, '')
    
    #2. int type value extract
    number_pattern_i = re.compile(r"\d+") 
    numbers_i = number_pattern_i.findall(new_text)
    numbers = numbers_f + numbers_i
    
    #3. convert float type
    temp =[]
    for i in numbers:
        f = float(i)
        temp.append(f)
    numbers = temp
    
    return numbers

def remove_numbers(text):
    no_numbers_text = re.sub(r'/d+', '', text)
    return no_numbers_text

def value_adjustment(ans_dic):
  if 'divide' not in ans_dic.keys():
    return ans_dic
  if '총 내용량' not in ans_dic.keys():
    return ans_dic

  total_val = extract_numbers(ans_dic['총 내용량'])[0] 
  total_unit = extract_english_strings(ans_dic['총 내용량'])[0]
  divide_val = extract_numbers(ans_dic['divide'])[0]
  divide_unit = ans_dic['divide unit']

  if divide_unit != total_unit:
    if total_unit == 'kg' or total_unit=='l':
      total_val = total_val*1000
      #print("unit changed", total_unit, " -> ", divide_unit)


  ratio = total_val/divide_val
  
  #print("divide check result / ratio: ", ans_dic, ratio)
  
  for i in ans_dic.keys():
    if (i=='총 내용량' or i=='divide' or i=='divide unit'):
      continue
    else:
      new_val = round(extract_numbers(ans_dic[i])[0] * ratio, 3) # round 3
      ans_dic[i] = str(new_val) + extract_english_strings(ans_dic[i])[0]

  del ans_dic['divide']
  del ans_dic['divide unit']

  return ans_dic
  
 
def plt_imshow(title='image', img=None, figsize=(8 ,5)):
    plt.figure(figsize=figsize)
 
    if type(img) == list:
        if type(title) == list:
            titles = title
        else:
            titles = []
 
            for i in range(len(img)):
                titles.append(title)
 
        for i in range(len(img)):
            if len(img[i].shape) <= 2:
                rgbImg = cv2.cvtColor(img[i], cv2.COLOR_GRAY2RGB)
            else:
                rgbImg = cv2.cvtColor(img[i], cv2.COLOR_BGR2RGB)
 
            plt.subplot(1, len(img), i + 1), plt.imshow(rgbImg)
            plt.title(titles[i])
            plt.xticks([]), plt.yticks([])
 
        plt.show()
    else:
        if len(img.shape) < 3:
            rgbImg = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)
        else:
            rgbImg = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
 
        plt.imshow(rgbImg)
        plt.title(title)
        plt.xticks([]), plt.yticks([])
        plt.show()

def putText(image, text, x, y, color=(0, 255, 0), font_size=22):
    if type(image) == np.ndarray:
        color_coverted = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(color_coverted)
 
    if platform.system() == 'Darwin':
        font = 'AppleGothic.ttf'
    elif platform.system() == 'Windows':
        font = 'malgun.ttf'
    else:
        font = 'NanumGothic.ttf'
        
    image_font = ImageFont.truetype(font, font_size)
    font = ImageFont.load_default()
    draw = ImageDraw.Draw(image)
 
    draw.text((x, y), text, font=image_font, fill=color)
    
    numpy_image = np.array(image)
    opencv_image = cv2.cvtColor(numpy_image, cv2.COLOR_RGB2BGR)
 
    return opencv_image

def execute_api(img_path) :
    client_options = {'api_endpoint': 'eu-vision.googleapis.com'}
    client = vision.ImageAnnotatorClient(client_options=client_options)
    
    img = cv2.imread(img_path)
    # cap = cv2.VideoCapture(0)
    # roi_img = img.copy()

    with io.open(img_path, 'rb') as image_file:
        content = image_file.read()

    image = vision.Image(content=content)
 
    response = client.text_detection(image=image)
    texts = response.text_annotations
    print("execute_api = text: ",texts,len(texts))
    #exception - recognize nothing in img : len(texts) = 0
    # if len(texts):
    #     texts = {"description":0}
    result_ocr = "{}".format(texts[0].description)
    
    if response.error.message:
        raise Exception(
            '{}/nFor more info on error messages, check: '
            'https://cloud.google.com/apis/design/errors'.format(
                response.error.message))

    return result_ocr

def regular_expression(text_result) :
  # 사전에 정의된 올바른 단어 목록
  dictionary = ['총', '내용량', '탄수화물', '나트륨', '지방', '당류', '트랜스지방', '포화지방', '콜레스테롤', '단백질']

  # 임계값 설정
  THRESHOLD = 0.7

  # 수정된 결과 목록
  corrected_results = []

  for ocr_line in text_result:
    corrected_line = ocr_line
    # 가장 유사한 단어 찾기
    matches = difflib.get_close_matches(ocr_line, dictionary, n=1, cutoff=THRESHOLD)
    # 유사한 단어가 있으면 사용, 없으면 원래 단어 사용
    corrected_word = matches[0] if matches else ocr_line
    # 원래 문장에서 단어 교체
    corrected_line = corrected_line.replace(ocr_line, corrected_word, 1)
    corrected_results.append(corrected_line)

  return corrected_results

def is_float(word):
  '''
  숫자인지 확인
  '''
  try:
    float_value = float(word)
    return True

  except ValueError:
    return False

def is_korean(word) :
    korean_range = (0xAC00, 0xD7AF)
    if korean_range[0] <= ord(word) <= korean_range[1] :
        return True
    else :
        return False

#first_ocr = execute_api("C:/Users/82108/Desktop/sample/sample05.png").replace('/n', " ")
#print(first_ocr.split(" "))
#second_ocr = (''.join(first_ocr.split("/n", " "))).replace(" ", "")

def horizontal(output_text) :
    a = output_text.index('나트륨')
    b = output_text.index('kcal')
    c = 0
    
    for x_ in range(a,b) :
        if is_float(output_text[x_][0]) == False and is_float(output_text[x_+1][0]) == True :
            c = x_+1

    ans_num = {}
    if is_float(output_text[c][-1]) == True : 
        ans_num["열량"] = output_text[c] + 'kcal'
    
    for num in range(len(output_text)) :
        if '총 내용량' in  output_text[num] :
            if is_float(output_text[num + 1][0]) == True :
                ans_num['총 내용량'] = output_text[num+1]

    for i in range(c-a) :
        if is_float(output_text[b+i+1][-1]) == True :
            output_text[b+i+1] = output_text[b+i+1][:-1] + 'g'
        ans_num[output_text[a+i]] = output_text[b+i+1]
    

    yeongyang = ['열량', '총 내용량','탄수화물','지방','단백질']
    ans_dic = {}
    
    for i in yeongyang :
        if (i in list(ans_num)) and (48<= ord(ans_num[i][0]) <= 57) and (ans_num[i][-1] in ['g',')', 'l', 'L', 'KG', '8', '9']):
            if is_float(ans_num[i]) == True :
                if ans_num[i][-1] == '9' or ans_num[i][-1] == '8' :
                    ans_dic[i] = ans_num[i][:-1] + 'g'
            else : 
                ans_dic[i] = ans_num[i]
    
    chek_words = ["ml 당", "ml당", "g 당", "g당" , "g)당", "g) 당", '당'] #나눠진 경우에 대한 확인 문자
    units =      ["ml",   "ml",    "g",   "g",    "g", "g", 'none']
    divide_unit = ''
    count = 0
    for check in chek_words:
        for word in output_text:
          if check == remove_numbers(word):
           
            divide_unit = units[count]
            val_in_word = (check!=word)

            values = output_text.index(word) - 1
            if(divide_unit == 'none'):
              divide_unit = extract_english_strings(output_text[values])[0]
              if(val_in_word):
                ans_dic['divide'] = str(extract_numbers(word)[0]) + divide_unit
              else:
                ans_dic['divide'] = output_text[values]
            else:
              if(val_in_word):
                ans_dic['divide'] = str(extract_numbers(word)[0]) + divide_unit
              else:
                ans_dic['divide'] = output_text[values] + divide_unit

            ans_dic['divide unit'] = divide_unit
        count = count+1

    return ans_dic


def vertical(output_text) : 
    # 기준 및 칼로리 구분하기
    ans_dic = {}
    ending = 0

    for num in range(len(output_text)) :
        if 'kcal' == output_text[num].lower() :
            ans_dic['열량'] = output_text[num-1] + 'kcal'
            ending = 1
        elif output_text[num][-4:].lower() == 'kcal' :
            ans_dic['열량'] = output_text[num]
            ending = 1
        if ending == 0 : 
            continue
        else : 
            break
    
    for num in range(len(output_text)) :
        if '총 내용량' in  output_text[num] :
            if is_float(output_text[num + 1][0]) == True :
                ans_dic['총 내용량'] = output_text[num+1]
        break
  #필요한 정보 뽑아내기
    yeongyang = ['총 내용량', '열량', '탄수화물','지방','단백질']
    for i in yeongyang :
        if i in output_text :
            keys = output_text.index(i)
            values = keys + 1
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            if 48 <= ord(output_text[values][0]) <= 57  and ( output_text[values][-1] in ['g',')', 'l', 'L', 'KG', '8', '9'])  :
                if is_float(output_text[values]) == True :
                    if output_text[values][-1] == '9' or output_text[values][-1] == '8' :
                        ans_dic[output_text[keys]] = output_text[values][:-1] + 'g'
                else : 
                    ans_dic[output_text[keys]] = output_text[values]
    
    chek_words = ["ml 당", "ml당", "g 당", "g당" , "g)당", "g) 당", '당'] #나눠진 경우에 대한 확인 문자
    units =      ["ml",   "ml",    "g",   "g",    "g", "g", 'none']
    divide_unit = ''
    count = 0
    for check in chek_words:
        for word in output_text:
          if check == remove_numbers(word):
            #print(word, check)
            divide_unit = units[count]
            val_in_word = (check!=word)

            values = output_text.index(word) - 1
            if(divide_unit == 'none'):
              divide_unit = extract_english_strings(output_text[values])[0]
              if(val_in_word):
                ans_dic['divide'] = str(extract_numbers(word)[0]) + divide_unit
              else:
                ans_dic['divide'] = output_text[values]
            else:
              if(val_in_word):
                ans_dic['divide'] = str(extract_numbers(word)[0]) +divide_unit
              else:
                ans_dic['divide'] = output_text[values] + divide_unit

            ans_dic['divide unit'] = divide_unit
        count = count+1

    return ans_dic


def ocr_check(img_path) :
    # output : e,result_dic
    print("check_img_path:", img_path)
    ocr_result = (execute_api(img_path).replace('\n', " ")).split(" ")
    print("first:", ocr_result)

    result_modif = []
    for i in ocr_result :
        para = False
        if len(i) != 1 : 
            for e in range(len(i)-1) : 
                if (is_korean(i[e]) == True) and (is_float(i[e+1]) == True):
                    para = True
                    result_modif.append(i[:e+1])
                    if i[-1] not in ['g', 'l'] :
                        new_word = i[e+1:]
                        for k in range(len(new_word)) :
                            if new_word[k] in ['g','l'] :
                                result_modif.append(new_word[:k+1])
                                result_modif.append(new_word[k+1:])
                    
                    else :
                        result_modif.append(i[e+1:])
                if e == len(i)-2 :
                    if para == False : 
                        result_modif.append(i)
        else : 
            result_modif.append(i)
    
    output_text = regular_expression(result_modif)
    
    temp = []
    for i in output_text:
        i = i.split('(')
        for j in i:
            j = j.split(')')
            for k in j :
                k = k.split('/')
                temp.extend(k)
    
    
    output_text = temp
    
    new_output = []
    for x in range(len(output_text)) :
        if output_text[x] in ['g', 'mg', 'l', 'ml'] :
            del new_output[-1]
            new_output.append(output_text[x-1] + output_text[x])
        elif output_text[x-1] == "총" and output_text[x] == "내용량" :
            new_output.append(output_text[x-1] + " " + output_text[x])
        else :
            new_output.append(output_text[x])
    

    err_dic = {}
    e = 1
    # print("third:", new_output)
    # 형태 구분(한글 - 한글 형태인지, 한글 - 숫자 형태인지 확인)
    if '나트륨' in new_output :
        a = new_output.index('나트륨')
        re = False
    else :
        print( "오류가 발생하였습니다. 사진을 더 정확히 찍어주세요.")
        err_dic["erro"] = e
        return err_dic
    korean_range = (0xAC00, 0xD7AF)

    char = new_output[a+1][0]
    if is_korean(char) == True :
        re = True
        if 'kcal' in new_output : 
            answer_is = horizontal(new_output)
        else : 
            print("오류가 발생하였습니다. 사진을 더 정확히 찍어주세요.")
            err_dic["erro"] = e
            return  err_dic
    if re == False :
        answer_is = vertical(new_output)

    #############################################
    # print("before val adj: ", answer_is , type(answer_is))
    answer_is = value_adjustment(answer_is)
    #############################################
    e = 0 # no erro
    answer_is["erro"] = 0
    # print("final2",answer_is)
    return answer_is

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# flask 

# calculate bmi , Carb&protein&fat g
def calculate_bmi(height, weight):
    h_m = height / 100
    bmi = round(weight / (h_m ** 2), 2)
    print("bmi_res" , bmi)
    return {"bmi": bmi}

def PA_cal(age,gender, pa_level):
  PA = 0
  if age >=3 and age <=19:
    if gender == 'm':

      if pa_level == 0 :
        PA = 1.0
      elif pa_level == 1 :
        PA = 1.13
      elif pa_level == 2 :
        PA = 1.26
      elif pa_level == 3 :
        PA = 1.42

    elif gender == 'f':

      if pa_level == 0 :
        PA = 1.0
      elif pa_level == 1 :
        PA = 1.16
      elif pa_level == 2 :
        PA = 1.31
      elif pa_level == 3 :
        PA = 1.56

  elif age >=20 :
    if gender == 'm':

      if pa_level == 0 :
        PA = 1.0
      elif pa_level == 1 :
        PA = 1.11
      elif pa_level == 2 :
        PA = 1.25
      elif pa_level == 3 :
        PA = 1.48

    elif gender == 'f':

      if pa_level == 0 :
        PA = 1.0
      elif pa_level == 1 :
        PA = 1.12
      elif pa_level == 2 :
        PA = 1.27
      elif pa_level == 3 :
        PA = 1.45

  return PA
def calculate_tee(age, gender, pa_level, weight, height):
    pa = 0.0
    x = 0
    TEE_res = 0.0
    h_m = height/ 100

    # PA
    pa = PA_cal(age,gender, pa_level)

    # TEE
    if age <= 0 :
        TEE_res = 89 * weight - 100 + 22 #excelt 0~5 month

    elif age <= 2:
        TEE_res = 89 * weight - 100 + 20

    elif age <=19:
    #
        if age <=8 :
            x = 20
        else :
            x= 25
    #
        if gender == 'm':
            TEE_res = 88.5-61.9 * age + pa * (26.7*weight + 903 * h_m) + x
        elif gender == 'f':
            TEE_res = 135.3 - 30.8 * age + pa * (10 * weight + 934 * h_m) + x

    else:
        if gender == 'm':
            TEE_res = 662 - 9.53* age + pa * (15.91 * weight + 539.6 * h_m)
        elif gender == 'f':
            TEE_res = 354 - 6.91 * age + pa * (9.36 * weight + 726 * h_m)
    print(TEE_res)
    return round(TEE_res,0)    

def calculate_nutrient_ratio(purpose_lv, TEE):
    #Carbon , Protein, Lipid intake(g)
        # Carbohydrate  4kcal /1g
        # Protein 4kcal / 1g
        # Lipid 9kcal /1g
    dic_g = {}
    # c_rate = 0
    # p_rate = 0
    # l_rate = 0
    tee = TEE

  #purpose ->c,p,l_ratio, new_tee
    if purpose_lv == 0: # Stay
        c_rate = 60
        p_rate = 15
        l_rate = 25
    elif purpose_lv == 1 : # Diate
        c_rate = 40
        p_rate - 20
        l_rate - 40
    elif purpose_lv == 2 : #Bulk Up
        tee = tee + 300
        c_rate = 55
        p_rate = 20
        l_rate = 25

    #TEE ->c,p,l kcal -> c,p,l g

    c_g = (tee * c_rate/100)/4
    p_g = (tee * p_rate / 100)/4
    l_g = (tee * l_rate / 100)/9

    dic_g["Carbohydrate"] = round(c_g,0)
    dic_g["Protein"] = round(p_g,0)
    dic_g["Lipide"] = round(l_g,0)
    return tee ,dic_g

def save_base64_image(base64_string, filename):
    # base64 decoding 
    image_data = base64.b64decode(base64_string)
    
    # temporary store img(decoding base64) by file in server 
    with open(filename, 'wb') as f:
        f.write(image_data)
    print(f"이미지가 {filename}에 저장되었습니다.")

@app.route('/')
def home():
    return 'This is Home!'

# input human info , output calcultate bmi, C,P,F
@app.route("/calculate_status", methods=["POST"])
def calculate_status():

    data= request.get_json()
    if not data : 
       return  jsonify({"ocr_erro": "Nuser_info provided"})

    age = int(data["age"])
    height = float(data["height"])
    weight = float(data["weight"])
    gender = data["gender"] # 'm', 'f'
    pa_level = int(data["pa_level"]) # 0,1,2,3
    purpose_lv = int(data["purpose"])
    print( age, height,weight,gender,pa_level,purpose_lv)

    # Calculate BMI
    bmi_result = calculate_bmi(height, weight)

    # Calculate TEE (For demonstration, using a constant value)
    tee_result = calculate_tee(age, gender, pa_level, weight, height)

    # Calculate nutrient ratio
    tee_result ,nutrient_ratio_result = calculate_nutrient_ratio(purpose_lv, tee_result)

    result = {
        "bmi": bmi_result,
        "TEE": tee_result,
        "nutrient_ratio": nutrient_ratio_result
    }


    return jsonify(result)

# ocr : input base24 encoding img
'''
output= {
    '열량': '100g당kcal', '총 내용량': '250g', 
    '탄수화물': '15g', '지방': '41g', '단백질': '1g',
      'erro': 3
}
<erro>
0: no erro
1 : "erro , take a picture more carefully" 
2 : "no image."
3 : "ocr can't read image. return origin image " 
the type of error about 0,3 is working 
'''

@app.route("/perform_ocr", methods=["POST"])
def perform_ocr():
    input_path = "./input_test.jpg" # store base64 decoding (flutter->flask)
    save_path = "./test_image_save.jpg" #store preprocessing img_path for ocr
    no_image=0
    ocr_result = {}

   # (1) receive request 'image'
    file = request.get_json()
    # # if not file : 
    # #    return  jsonify({"ocr_result": "No image provided"})
    base64_img= file['image']
    
    #---------- try test---------------(delete)
    # img_path = "./test_img/test4.jpg"
    # encode_img=  base64.b64encode(open(img_path, "rb").read())
    # base64_img = encode_img
    ######

    #base64 Decoding and store orgin_image in input_path(str-> img) 
    save_base64_image(base64_img, input_path)
    image_path = input_path
    
    try:
        image = cv2.imread(image_path)
        # print(type(image))
        
    except:
        no_image=1
   
    if no_image:
        e = 2
        ocr_result["erro"] = e
        print("이미지가 존재하지 않습니다. 이미지를 확인해주세요.")
    else:
        result = predict(image)
        print(result, len(result))
        if len(result)!=1:#예외처리  
            cv2.imwrite(save_path, result)
        else:
            e = 3
            ocr_result["erro"] = e
            print("인식한 영양정보표가 없어 원본이미지로 진행합니다.")
            save_path = image_path
        
       
        ocr_result= ocr_check(save_path) # dict 
        # renew erro type 
        
        # print("final",ocr_result, type(ocr_result))
    print("success")
    return jsonify(ocr_result)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
