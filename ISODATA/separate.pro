;+
;  分裂程序
; :AUTHOR: ChenAi
;-
PRO Separate,num,center,nc,nr,nl,$
    flag,S_num,std_avr,std,final_class
    
  COMPILE_OPT IDL2
  
  CATCH,err_status
  IF(err_status NE 0) THEN BEGIN
    PRINT,'Somthing Wrong in Pro Separate!'
    RETURN
  ENDIF
  
  ;第一种分裂情况，类数过少,把类内距离最大的分裂
  IF (num LT final_class) THEN BEGIN
    num = num + 1
    tmp_center = FLTARR(num,nl)
    max_std = MAX(std_avr,max_pos)
    
    FOR i=0,max_pos-1 DO $
      tmp_center[i,*] = center[i,*]
      
    tmp_center[max_pos,*] = center[max_pos,*] + std[max_pos,*]
    tmp_center[max_pos+1,*] = center[max_pos,*] - std[max_pos,*]
    
    FOR i = max_pos+2,num-1 DO $
      tmp_center[i,*] = center[i-1,*]
      
    center = tmp_center
    
    RETURN
  ENDIF
  
  
  ;第二种分裂情况，某一类的均方差超过了指定参数
  index = WHERE(std_avr GT S_num,sep_num)
  IF(sep_num EQ 0) THEN RETURN   ;没有需要分裂的类
  
  FOR i=0,sep_num-1 DO BEGIN
    num = num + 1
    tmp_center = FLTARR(num,nl)
    max_pos = index[i]
    
    FOR i=0,max_pos-1 DO $
      tmp_center[i,*] = center[i,*]
      
    tmp_center[max_pos,*] = center[max_pos,*] + std[max_pos,*]
    tmp_center[max_pos+1,*] = center[max_pos,*] - std[max_pos,*]
    
    FOR i = max_pos+2,num-1 DO $
      tmp_center[i,*] = center[i-1,*]
      
    center = tmp_center
    index = index + 1
  ENDFOR
  
END