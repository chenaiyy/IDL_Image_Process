;+
; 合并操作
;
;
;
; :AUTHOR: ChenAi
;-
PRO Combinate,num,center,nc,nr,nl,$
    flag,L_num,D_num,dis_class,final_class
    
  COMPILE_OPT IDL2
  
  CATCH,err_status
  IF(err_status NE 0) THEN BEGIN
    PRINT,'Somthing Wrong in PRO Combinate!'
    RETURN
  ENDIF
  
  
  ;第一种聚类情况：类数过多，合并类距最大的几组
  IF(initial_class GT 2*final_class) THEN BEGIN
    init_num = num
    index = REPLICATE(1L,num+L_num)
    
    idx = Reverse(SORT(dis_class))
    FOR i=0,L_num-1 DO BEGIN
      index_ij = Findinx(init_num,idx[i])
      a = index_ij[0]
      b = index_ij[1]
      index[a] = 0
      index[b] = 0
      tmp_center = (center[a,*]+center[b,*])/2
      ;合并开始
      num = num+1
      center = [center,tmp_center]
    ENDFOR
    keep = WHERE(index EQ 1)
    center = center[keep,*]
    
    num = N_ELEMENTS(center)
    
    RETURN
    
  ENDIF
  
  ;第二种聚类情况：类间距低于指定值
  index = WHERE(dis_class LT D_num,com_num)
  IF com_num EQ 0 THEN RETURN
  
  idx = SORT(dis_class)
  L_num = L_num < com_num
  init_num = num
  index = REPLICATE(1L,num+L_num)
  FOR i=0,L_num-1 DO BEGIN
    index_ij = Findinx(init_num,idx[i])
    a = index_ij[0]
    b = index_ij[1]
    index[a] = 0
    index[b] = 0
    tmp_center = (center[a,*]+center[b,*])/2
    ;合并开始
    num = num+1
    center = [center,tmp_center]
  ENDFOR
  keep = WHERE(index EQ 1)
  center = center[keep,*]
  
  num = N_ELEMENTS(center)
  


END


FUNCTION Findinx,num,idx

  COMPILE_OPT IDL2
  
  index_ij = INTARR(2)
  
  CATCH,err_status
  IF(err_status NE 0) THEN BEGIN
    PRINT,'Somthing Wrong in Function Findinx!'
    RETURN, -1
  ENDIF
  
  cnt = 0
  FOR i=0,num-2 DO BEGIN
    FOR j=i+1,num-1 DO BEGIN
      IF cnt EQ idx THEN BEGIN
        index_ij[0] = i
        index_ij[1] = j
        RETURN, index_ij
      ENDIF
      cnt = cnt + 1
      
    ENDFOR
  ENDFOR
  
END