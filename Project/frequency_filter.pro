;+
;  一些频率域滤波功能，包括
;  巴特沃斯滤波
;  带通滤波
;
; :AUTHOR: ChenAi
;-
PRO Frequency_filter
  ; 获取影像文件
  fname = DIALOG_PICKFILE(/READ, FILTER = '*.bmp')
  Img_Data = Read_bmp(fname)
  
  IF SIZE(Img_Data,/n_dimensions) EQ 3 THEN BEGIN
    PRINT,'It is a color image, we will only do 1 band!'
    Img_Data = REFORM(Img_Data[0,*,*])
  ENDIF
  
  img_o = Image(Img_Data, TITLE='Origin Image', $
    LAYOUT=[2,3,1],/CURRENT)
    
  ;Get Histogram of origin image
  dim = SIZE(Img_Data,/dimensions)
  row = dim[1]
  col = dim[0]
  
  ;加一些噪音
  xCoords = LINDGEN(col,row) MOD row
  yCoords = TRANSPOSE(xCoords)
  noise = -SIN(xCoords*2)-SIN(yCoords*2)
  imageNoise = Img_Data + 20*noise
  img_o = Image(imageNoise, TITLE='Image With Noise', $
    LAYOUT=[2,3,2],/CURRENT)
    
  ;巴特沃斯滤波低通滤波
  B_filter = Butterworth(col, row)
  B_img = FFT( FFT(imageNoise, -1) * B_filter, 1 )
  img_B = Image(B_img, TITLE='Butterworth Low-pass(Noise Image)', $
    LAYOUT=[2,3,3],/CURRENT)
    
  ;巴特沃斯高通滤波
  bh_img = Bandpass_filter(Img_Data,0.3,1,butterworth=10)
  img_bh = Image(bh_img, TITLE='Butterworth High-pass(Origin Image)', $
    LAYOUT=[2,3,4],/CURRENT)
    
  ;带通滤波，用到了高斯滤波函数
  gauss_img = Bandpass_filter(Img_Data,0.3,1,/GAUSSIAN)
  img_g = Image(gauss_img, TITLE='Bandpass Filter Gaussian(Origin Image)', $
    LAYOUT=[2,3,5],/CURRENT)
    
  ;带通滤波，用到了高斯滤波函数
  gauss_img = Bandpass_filter(imageNoise,0,0.4,/GAUSSIAN)
  img_g = Image(gauss_img, TITLE='Bandpass Filter Gaussian(Noise Image)', $
    LAYOUT=[2,3,6],/CURRENT)
    
END