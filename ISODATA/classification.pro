;+
; :DESCRIPTION:
;    Describe the procedure.
;  计算距离并对图像分类
;  采用的是欧氏距离
;  img: 输入的影像
;  num: 分类的数目
;  center: 类的中心
;  nc,nr,nl:图像的列，行以及维数
;  min_num: 每类的最小个数
;  flag: 分类后每个像素对应的类
;  stat_num: 分类后每个类对应的像元数目
;
; :AUTHOR: ChenAi
;-
PRO Classification,img,num,center,nc,nr,nl,min_num,$
    flag=flag,stat_num=stat_num
    
  COMPILE_OPT IDL2
  
  stat_num = ULON64ARR(num)
  
;  CATCH,err_status
;  IF (err_status NE 0) THEN BEGIN
;    PRINT,'something wrong in PRO Classifacation'
;    RETURN
;  ENDIF
  
  ;计算距离
  dis = FLTARR(num)
  flag = BYTARR(nc,nr)
  FOR i=0L, nc-1 DO BEGIN
    FOR j=0L, nr-1 DO BEGIN
      FOR k=0,num-1 DO BEGIN
        dis[k] = SQRT(TOTAL((img[*,i,j]-center[k,*])^2))
      ENDFOR
      min_dis = MIN(dis,min_pos)
      stat_num[min_pos] = stat_num[min_pos] + 1
      flag[i,j] = min_pos
    ENDFOR
  ENDFOR
  
  ;检查是否有某一类的像元数目小于指定的最小类包含的像元数
  nnum = MIN(stat_num,min_pos)
  ;如果有，则把该类的中心舍去 重新进行分类
  IF (nnum LT min_num) THEN BEGIN
    num = num - 1
    tmp_center = FLTARR(num,nl)
    
    FOR i=0,min_pos-1 DO $
      tmp_center[i,*] = center[i,*]
    FOR i = min_pos,num-1 DO $
      tmp_center[i,*] = center[i+1,*]
      
    center = tmp_center
    ;重新分类
    Classification,img,num,center,nc,nr,nl,min_num,$
      flag=flag,stat_num=stat_num
  ENDIF
  
END
