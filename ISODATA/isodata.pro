;+
; :DESCRIPTION:
; Text file encoding is UTF-8
;
;  这是IDL编写的一个ISODATA非监督分类的例子
;
; :AUTHOR: ChenAi
;-
PRO Isodata
  COMPILE_OPT IDL2
  
;  CATCH,err_status
;  IF(err_status NE 0) THEN BEGIN
;    PRINT,'Something wrong in PRO Isodata!'
;    RETURN
;  ENDIF
  ;选择并打开图像文件
  queryStatus = Query_image( SUPPORTED_READ=filter)
  FOR i=0L,N_ELEMENTS(filter)-1 DO BEGIN
    IF filter[i] EQ 'JPEG' THEN filter[i] = 'JPG'
    filter[i] = '*.'+STRLOWCASE(filter[i])
  ENDFOR
  
  fname = DIALOG_PICKFILE(/READ, filter=filter)
  Img = Read_image(fname)
  
  ;获取文件的信息
  dim = SIZE(Img,/dimensions)
  IF SIZE(Img,/n_dimensions) EQ 2 THEN BEGIN
    lay = 1 ;维数
    row = dim[1] ;行
    col = dim[0] ;列
  ENDIF ELSE BEGIN
    lay = dim[0]
    row = dim[2]
    col = dim[1]
  ENDELSE
  
  ;设定ISODATA的一些初始参数
  initial_class = 8   ;初始类数目
  final_class = 6     ;最终类数目
  N = row*ULONG64(col) ;总的像元个数
  min_num = ULONG(N*0.08)   ;每类最小的像元数目
  max_itr = 8     ;最大的迭代次数
  L_num=2      ;每次迭代中允许合并的最大类的最大对数
  S_num=2.5     ;一个聚类域中样本距离分布的标准差,大于此数就分裂;
  D_num=0.01     ;两聚类中心之间的最小距离,如小于此数,两个聚类合并;
  
  ;自动建立初始类中心
  class_center = FLTARR(initial_class,lay)
  
  FOR i=0L,lay-1 DO BEGIN
    tmp=0.0
    tmp=MAX(Img[i,*,*])-MIN(Img[i,*,*])
    FOR j=0L,initial_class-1 DO BEGIN
      class_center[j,i]=(j+0.5)*(tmp/initial_class)+$
        MIN(Img[i,*,*])
    ENDFOR
  ENDFOR
  
  ;初始分类
  Classification,img,initial_class,class_center,col,$
    row,lay,min_num,$
    flag=flag,stat_num=stat_num
  ;重新计算类中心，并计算相关统计量
  Class_stat,img,initial_class,class_center,col,row,lay,$
    flag,std_avr=std_avr,dis_class=dis_class,std_class=std_class
    
  itr = 1  ;当前迭代次数
  WHILE(itr LE max_itr) DO BEGIN
    PRINT,'第',itr,'次迭代'
    ;进行类的分裂合并
    ;当当前类数目小于预期数目时进行分裂
    IF(initial_class LT final_class) THEN BEGIN
      Separate,initial_class,class_center,col,row,lay,$
        flag,S_num,std_avr,std_class,final_class
      GOTO, JUMP1
    ENDIF
    ;当前类数过多时,进行合并操作
    IF(initial_class GT 2*final_class) THEN BEGIN
      Combinate,initial_class,class_center,col,row,lay,$
        flag,L_num,D_num,dis_class,final_class
      GOTO, JUMP1
    ENDIF
    ;类数适当，进行正常的分裂合并操作
    itr_mod = itr MOD 2
    IF (itr_mod EQ 0) THEN BEGIN  ;迭代次数为偶数时进行合并
      Combinate,initial_class,class_center,col,row,lay,$
        flag,L_num,D_num,dis_class,final_class
    ENDIF ELSE BEGIN        ;迭代次数为奇数时进行分裂
      Separate,initial_class,class_center,col,row,lay,$
        flag,S_num,std_avr,std_class,final_class
    ENDELSE
    
    JUMP1:
    ;重新分类
    Classification,img,initial_class,class_center,col,$
      row,lay,min_num,$
      flag=flag,stat_num=stat_num
    ;重新计算类中心，并计算相关统计量
    Class_stat,img,initial_class,class_center,col,row,lay,$
      flag,std_avr=std_avr,dis_class=dis_class,std_class=std_class
      
    ;当迭代结果已经满足条件时，无需迭代
    itr_over = Itr_is_ok(initial_class,std_avr,dis_class,$
      final_class,S_num,D_num)
    IF  itr_over EQ 1  THEN BREAK
    
    ;迭代次数增加1
    itr = itr + 1
  ENDWHILE
  
  ;创建颜色
  begcolor = [255,0,255]
  endcolor = [0,255,0]
  scaleFactor = FINDGEN(initial_class)/(initial_class-1)
  mycolor = BYTARR(3,initial_class)
  FOR j=0,2 DO mycolor[j,*] = begcolor[j] + ($
    endcolor[j]-begcolor[j])*scaleFactor
    
  ISODATA_img = BYTARR(3,col,row)
  FOR i=0L, col-1 do begin
    for j=0L,row-1 do begin
      mm = flag[i,j]
      ISODATA_img[*,i,j] = mycolor[*,mm]
    endfor
  endfor
  
  iso_img = image(ISODATA_img)
  
END

FUNCTION Itr_is_ok,initial_class,std_avr,dis_class,$
    final_class,S_num,D_num
    
  COMPILE_OPT IDL2
  
  CATCH,err_status
  IF(err_status NE 0) THEN BEGIN
    PRINT,'Somthing Wrong in Function Itr_is_ok!'
    RETURN, -1
  ENDIF
  
  IF initial_class LT final_class THEN RETURN, -1
  IF MAX(std_avr) GT s_num THEN RETURN,-1
  IF MIN(dis_class) LT D_num THEN RETURN,-1
  
  RETURN,1
  
END
