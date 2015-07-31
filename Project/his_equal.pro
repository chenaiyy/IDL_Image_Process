;+
; :DESCRIPTION:
;    Describe the procedure.
;     Histogram equalization
;
; :AUTHOR: ChenAi
;-
PRO  His_equal

  ; Get the Image
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
  
  pix_num = INTARR(256)
  FOR i=0L,col-1 DO BEGIN
    FOR j=0L,row-1 DO BEGIN
      pix_num[Img_Data[i,j]] = pix_num[Img_Data[i,j]] + 1
    ENDFOR
  ENDFOR
  
  P_r = pix_num/DOUBLE(col)/DOUBLE(row)
  ymax = 1.5*MAX(P_r)
  bplot_o = Barplot(P_r,yrange=[0,ymax], TITLE="Origin Histogram",$
    LAYOUT=[2,3,2],/CURRENT)
    
  ;Histogram equalization
  s = FLTARR(256)
  FOR i=0L,255 DO BEGIN
    s[i] = TOTAL(P_r[0:i])
  ENDFOR
  
  new_img = BYTARR(col,row)
  FOR i=0L,col-1 DO BEGIN
    FOR j=0L,row-1 DO BEGIN
      ;Byte 取整的时候向下取整
      new_img[i,j] = BYTE(s[Img_Data[i,j]]*255)
    ENDFOR
  ENDFOR
  
  img_n = Image(new_img, TITLE='New Image', $
    LAYOUT=[2,3,3],/CURRENT)
    
  ;get new Histogram
  pix_num_n = INTARR(256)
  FOR i=0L,col-1 DO BEGIN
    FOR j=0L,row-1 DO BEGIN
      pix_num_n[new_img[i,j]] = pix_num_n[new_img[i,j]] + 1
    ENDFOR
  ENDFOR
  
  P_s = pix_num_n/DOUBLE(col)/DOUBLE(row)
  ymax = 1.5*MAX(P_s)
  
  bplot_n = Barplot(P_s,yrange=[0,ymax], TITLE="New Histogram",$
    LAYOUT=[2,3,4],/CURRENT)
    
  ;IDL 自带函数进行直方图均衡化
  Img_IDL_HE=Hist_equal(Img_Data)
  img_IDL=Image(Img_IDL_HE,LAYOUT=[2,3,5],title='IDL',/CURRENT)
  
  pix_num_idl = INTARR(256)
  FOR i=0L,col-1 DO BEGIN
    FOR j=0L,row-1 DO BEGIN
      pix_num_idl[Img_IDL_HE[i,j]] = pix_num_idl[Img_IDL_HE[i,j]] + 1
    ENDFOR
  ENDFOR
  
  P_idl = pix_num_idl/DOUBLE(col)/DOUBLE(row)
  ymax = 1.5*MAX(P_idl)
  
  bplot_idl = Barplot(P_idl,yrange=[0,ymax], TITLE="IDL",$
    LAYOUT=[2,3,6],/CURRENT)
    
END