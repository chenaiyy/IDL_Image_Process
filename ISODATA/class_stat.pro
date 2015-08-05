;+
; :DESCRIPTION:
; 计算相关统计量，并获取新的类中心
; std_avr: 类内平均方差
; dis_class: 类间距离
;
; :AUTHOR: ChenAi
;-
PRO Class_stat,img,num,center,nc,nr,nl,$
    flag,std_avr=std_avr,dis_class=dis_class,std_class=std_class
    
  COMPILE_OPT IDL2
  
  std_class = FLTARR(num,nl)
  std_avr = FLTARR(num) ;类内平均方差
  dis_class = FLTARR(num*(num-1)/2) ;类间距离
  
  CATCH,err_status
  IF (err_status NE 0) THEN BEGIN
    PRINT,'Somthing Wrong in PRO class_stat!'
    RETURN
  ENDIF
  
  ;把每类的像元值提取出来
  tmp_img = REFORM(img,nl,ULONG64(nc*nr))
  FOR i=0,num-1 DO BEGIN
    index = WHERE(flag EQ i)
;    col_index = index MOD nc
;    row_index = index /nc
    FOR j=0,nl-1 DO BEGIN
      ;求新的聚类中心
      center[i,j] = Mean(img[j,index])
      ;各类的方差
      std_class[i,j] = Stddev(img[j,index])
    ENDFOR
    std_avr[i] = TOTAL(std_class[i,*])/nl
  ENDFOR
  
  ;求各类间距离
  cnt = 0
  FOR i=0,num-2 DO BEGIN
    FOR j=i+1,num-1 DO BEGIN
      FOR k=0,nl-1 DO BEGIN
        tmp = (center[i,k]-center[j,k])^2 / $
          (std_class[i,k]*std_class[j,k])
        dis_class[cnt] = dis_class[cnt] + tmp
      ENDFOR
      dis_class[cnt] = SQRT(dis_class[cnt])
      cnt = cnt + 1
    ENDFOR
  ENDFOR
  
END