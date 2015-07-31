;+
; :DESCRIPTION:
;    Describe the procedure.
; 伪彩色变换
;
; :AUTHOR: ChenAi
;-
PRO Pseudo_transform

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
  
  r = BYTARR(col,row)
  g = BYTARR(col,row)
  b = BYTARR(col,row)
  
  FOR i=0L,col-1 DO BEGIN
    FOR j=0L,col-1 DO BEGIN
      IF Img_Data[i,j] LT 64 THEN BEGIN
        r[i,j]=0
        g[i,j]=4*Img_Data[i,j]
        b[i,j]=255
      ENDIF
      IF (Img_Data[i,j] GE 64) AND $
        (Img_Data[i,j] LT 128) THEN BEGIN
        r[i,j]=0
        g[i,j]=255
        b[i,j]=511-4*Img_Data[i,j]
      ENDIF
      IF (Img_Data[i,j] GE 128) AND $
        (Img_Data[i,j] LT 192) THEN BEGIN
        r[i,j]=4*Img_Data[i,j]-511
        g[i,j]=255
        b[i,j]=0
      ENDIF
      IF Img_Data[i,j] GE 192 THEN BEGIN
        r[i,j]=255
        g[i,j]=1023-4*Img_Data[i,j]
        b[i,j]=0
      ENDIF
    ENDFOR
  ENDFOR
  
  Pseudo_img = BYTARR(3,col,row)
  Pseudo_img[0,*,*] = r
  Pseudo_img[1,*,*] = g
  Pseudo_img[2,*,*] = b
  img_pseudo = Image(Pseudo_img, TITLE='Pseudo Image', $
    LAYOUT=[1,2,2],/CURRENT)
    
END
