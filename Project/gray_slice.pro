;+
; :DESCRIPTION:
;  线性密度分割
; :AUTHOR: ChenAi
;-
PRO Gray_slice
  ; 获取影像文件
  fname = DIALOG_PICKFILE(/READ, FILTER = '*.bmp')
  Img_Data = Read_bmp(fname)
  
  
  IF SIZE(Img_Data,/n_dimensions) EQ 3 THEN BEGIN
    PRINT,'It is a color image, we will only do 1 band!'
    Img_Data = REFORM(Img_Data[0,*,*])
  ENDIF
  
  img_o = Image(Img_Data, TITLE='Origin Image', $
    LAYOUT=[1,2,1],/CURRENT)
    
  ;Get Histogram of origin image
  dim = SIZE(Img_Data,/dimensions)
  row = dim[1]
  col = dim[0]
  
  lay = 32L   ;分割层数
  dn_min = MIN(Img_Data)
  dn_max = MAX(Img_Data)
  IF (dn_max-dn_min+1) LT lay THEN BEGIN
    PRINT,"分割层数过多"
    RETURN
  ENDIF
  step = CEIL((dn_max-dn_min+1)/FLOAT(lay))
  
  ;创建颜色
  begcolor = [255,0,255]
  endcolor = [0,255,0]
  scaleFactor = FINDGEN(lay)/(lay-1)
  mycolor = BYTARR(3,lay)
  FOR j=0,2 DO mycolor[j,*] = begcolor[j] + ($
    endcolor[j]-begcolor[j])*scaleFactor
    
  ;进行密度分割
  img_slice = BYTARR(3,col,row)
  FOR i=0L,col-1 DO BEGIN
    FOR j=0L,row-1 DO BEGIN
      tmp = FLOOR((Img_Data[i,j]- dn_min)/step)
      img_slice[*,i,j] = mycolor[*,tmp]
    ENDFOR
  ENDFOR
  
  slice_img = Image(img_slice, TITLE='Slice Image', $
    LAYOUT=[1,2,2],/CURRENT)
    
END