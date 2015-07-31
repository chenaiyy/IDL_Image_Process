;+
; IHS变换
;
;
; :AUTHOR: ChenAi
;-
PRO Ihs
  ; 获取影像文件
  fname = DIALOG_PICKFILE(/READ, FILTER = '*.bmp')
  Img_Data = Read_bmp(fname)
  
  IF SIZE(Img_Data,/n_dimensions) NE 3 THEN BEGIN
    PRINT,'It is not a color image'
    RETURN
  ENDIF
  
  tmp = img_data[0,*,*]
  img_data[0,*,*] = img_data[2,*,*]
  img_data[2,*,*] = tmp
  
  tmp = 0
  
  img_o = Image(Img_Data, TITLE='Origin Image', $
    LAYOUT=[1,2,1],/CURRENT)
    
  dim = SIZE(Img_Data,/dimensions)
  row = dim[2]
  col = dim[1]
  
  ;IHS变换
  I = INDGEN(col,row)
  H = INDGEN(col,row)
  S = INDGEN(col,row)
  
  I = Img_data[0,*,*] + Img_data[1,*,*] + Img_data[2,*,*]
  H = FLOAT(Img_data[1,*,*] - Img_data[2,*,*])/(I-3*Img_data[1,*,*])
  S = (I-3*Img_data[1,*,*])/FLOAT(I)
  
  ihs_img = BYTARR(3,col,row)
  ihs_img[0,*,*] = BYTSCL(I)
  ihs_img[1,*,*] = BYTSCL(H)
  ihs_img[2,*,*] = BYTSCL(S)
  
  img_ihs = Image(ihs_img, TITLE='IHS Image', $
    LAYOUT=[1,2,2],/CURRENT)
    
END