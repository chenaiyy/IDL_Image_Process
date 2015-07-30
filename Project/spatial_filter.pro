;+
; :DESCRIPTION:
;    Describe the procedure.
;    简单的程序对图像进行
;    边缘增强(包括梯度法、Robert算子、拉普拉斯算子和Sobel算子)
;    平滑处理
;    定向滤波
;    中值滤波
;    目的是理清算法，故只以一个波段为例
;
; :AUTHOR: ChenAi
;-
PRO Spatial_filter

  ; 获取影像文件
  fname = DIALOG_PICKFILE(/READ, FILTER = '*.bmp')
  Img_Data = Read_bmp(fname)
  
  img_o = Image(Img_Data, TITLE='Origin Image', $
    LAYOUT=[3,3,1],/CURRENT)
    
  IF SIZE(Img_Data,/n_dimensions) EQ 3 THEN BEGIN
    PRINT,'It is a color image, we will only do 1 band!'
    Img_Data = REFORM(Img_Data[0,*,*])
  ENDIF
  
  ;Get Histogram of origin image
  dim = SIZE(Img_Data,/dimensions)
  row = dim[1]
  col = dim[0]
  
  ;影像增强处理
  ;1.梯度法
  grad_kernel1 = [[0,0,0],[0,1,-1],[0,0,0]]
  grad_kernel2 = [[0,0,0],[0,1,0],[0,-1,0]]
  grad_img_1 = ABS(CONVOL(Img_Data,grad_kernel1,$
    /EDGE_TRUNCATE))
  grad_img_2 = ABS(CONVOL(Img_Data,grad_kernel2,$
    /EDGE_TRUNCATE))
  grad_img = grad_img_1+grad_img_2
  
  img_grad = Image(BYTSCL(grad_img), TITLE='gradient filter', $
    LAYOUT=[3,3,2],/CURRENT)
    
  ;Rorbert 算子
  rorbert_k1 = [[0,0,0],[0,1,0],[0,0,-1]]
  rorbert_k2 = [[0,0,0],[0,0,1],[0,-1,0]]
  r_img1 = ABS(CONVOL(Img_Data,rorbert_k1,$
    /EDGE_TRUNCATE))
  r_img2 = ABS(CONVOL(Img_Data,rorbert_k2,$
    /EDGE_TRUNCATE))
  r_img = r_img1+r_img2
  img_robert = Image(BYTSCL(r_img), TITLE='Robert filter', $
    LAYOUT=[3,3,3],/CURRENT)
    
  ;拉普拉斯算子 ，IDL有自带的 也是用卷积写的
  lap_img = Laplacian(Img_Data,/add_back);可以设置不加背景关键字
  img_la = Image(BYTSCL(lap_img), TITLE='Laplacian filter', $
    LAYOUT=[3,3,4],/CURRENT)
    
  ;Sobel 算子 同样也是IDL自带 通过卷积所写
  Sob_img = SOBEL(Img_Data)
  img_sobel = Image(BYTSCL(Sob_img), TITLE='Sobel filter', $
    LAYOUT=[3,3,5],/CURRENT)
    
  ;平滑处理 同样为窗口卷积  采用自带函数Smooth
  ;加一些噪音
  xCoords = LINDGEN(col,row) MOD row
  yCoords = TRANSPOSE(xCoords)
  noise = -SIN(xCoords*2)-SIN(yCoords*2)
  imageNoise = Img_Data + 50*noise
  s_img = SMOOTH(imageNoise,[3,3],/EDGE_TRUNCATE)
  img_smooth = Image(BYTSCL(s_img), TITLE='Smooth', $
    LAYOUT=[3,3,6],/CURRENT)
    
  ;定向滤波
  ;取北向，选择滤波窗口为
  ;   1   1   1
  ;   1   -2  1
  ;   -1  -1 -1
  Noth_k = [[1,1,1],[1,-2,1],[-1,-1,-1]]
  img_north = CONVOL(Img_data,Noth_k,/EDGE_TRUNCATE)
  n_img = Image(BYTSCL(img_north), TITLE='North Filter', $
    LAYOUT=[3,3,7],/CURRENT)
    
  ;中值滤波  注意周围一圈没有做处理，要做处理可进行扩展
  img_mid = Img_data
  FOR i=1L,col-2 DO BEGIN
    FOR j=1L, row-2 DO BEGIN
      img_mid[i,j] = MEDIAN(imageNoise[i-1:i+1,j-1:j+1])
    ENDFOR
  ENDFOR
  mid_img = Image(BYTSCL(img_mid), TITLE='Median Filter', $
    LAYOUT=[3,3,8],/CURRENT)
    
  noise_img = Image(BYTSCL(imageNoise), TITLE='Image With Noise', $
    LAYOUT=[3,3,9],/CURRENT)
    
END