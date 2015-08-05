; docformat = 'rst'
; maxlike_run.pro
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;+
; :DESCRIPTION:
;       ENVI extension for classification of
;       a multispectral image with maximum likelihood
;       with option for reserving a random sample
;       of training data for subsequent evaluation
; :USES:
;      ENVI::
;      DIFFERENCE
; :AUTHOR:
;      Mort Canty (2009)
;-
PRO Maxlike_run
  COMPILE_OPT idl2
  FORWARD_FUNCTION Difference
  ENVI,/RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT
  PRINT, '---------------------------------'
  PRINT, 'Maximum Likelihood Supervised Classification'
  PRINT, SYSTIME(0)
  PRINT, '---------------------------------'
  ; select the image to be classified
  ENVI_SELECT, title='Enter File for classification', fid=fid, pos=pos, dims=dims
  IF (fid EQ -1) THEN BEGIN
    PRINT,'cancelled'
    RETURN
  ENDIF
  ENVI_FILE_QUERY, fid, fname=fname, xstart=xstart, ystart=ystart
  PRINT, 'file: '+fname
  num_cols=dims[2]-dims[1]+1
  num_rows=dims[4]-dims[3]+1
  num_bands=N_ELEMENTS(pos)
  ; tie point
  map_info = ENVI_GET_MAP_INFO(fid=fid)
  ENVI_CONVERT_FILE_COORDINATES, fid, dims[1], dims[3], e, n, /to_map
  map_info.mc[2:3]= [e,n]
  
  ; get associated ROIs
  roi_ids = ENVI_GET_ROI_IDS(fid=fid, roi_names=roi_names, roi_colors=roi_colors)
  IF (roi_ids[0] EQ -1) THEN BEGIN
    error=DIALOG_MESSAGE('No ROIs associated with the selected file',/error)
    PRINT, 'No ROIs associated with the selected file'
    PRINT, 'done'
    RETURN
  ENDIF
  ; compound widget for ROI selection
  base = WIDGET_AUTO_BASE(title='ROI Selection')
  wm   = WIDGET_MULTI(base, list=roi_names, uvalue='list', /auto)
  result = AUTO_WID_MNG(base)
  IF (result.accept EQ 0) THEN BEGIN
    error=DIALOG_MESSAGE('No ROIs selected',/error)
    PRINT, 'No ROIs selected'
    PRINT, 'done'
    RETURN
  ENDIF
  ptr = WHERE(result.list EQ 1, K)
  
  ; output destination
  base = WIDGET_AUTO_BASE(title='Output MaxLike classification to file')
  sb = WIDGET_BASE(base, /row, /frame)
  wp = WIDGET_OUTF(sb, uvalue='outf', /auto)
  result = AUTO_WID_MNG(base)
  IF (result.accept EQ 0) THEN BEGIN
    PRINT, 'output of classification aborted'
    RETURN
  ENDIF
  class_filename=result.outf
  OPENW, class_unit, class_filename, /get_lun
  base = WIDGET_AUTO_BASE(title='Output MaxLike rule image to file')
  sb = WIDGET_BASE(base, /row, /frame)
  wp = WIDGET_OUTF(sb, uvalue='outf', /auto)
  result = AUTO_WID_MNG(base)
  IF (result.accept EQ 0) THEN BEGIN
    PRINT, 'output of rule image cancelled'
    rule_filename='none'
    rule_flag=0
  END ELSE BEGIN
    rule_filename=result.outf
    rule_flag=1
    OPENW, rule_unit, rule_filename, /get_lun
  ENDELSE
  
  ; output file for test results
  
  outfile=DIALOG_PICKFILE(filter='*.tst',/write,/overwrite_prompt,title='Save test results to disk')
  IF (outfile EQ '') THEN BEGIN
    PRINT,'cancelled'
    RETURN
  ENDIF
  
  ; construct the training examples
  Gs = FLTARR(num_bands)
  Ls = FLTARR(K)
  FOR i=0,K-1 DO BEGIN
    Gs1 = ENVI_GET_ROI_DATA(roi_ids[ptr[i]],$
      fid=fid, pos=pos)
    Gs  = [[Gs], [Gs1]]
    Ls1 = FLTARR(K,N_ELEMENTS(Gs1[0,*]))
    Ls1[i,*]=1.0
    Ls = [[Ls], [Ls1]]
  ENDFOR
  Gs = Gs[*,1:N_ELEMENTS(Gs[0,*])-1]
  Ls = Ls[*,1:N_ELEMENTS(Ls[0,*])-1]
  m = N_ELEMENTS(Gs[0,*])
  
  ; split into training and test data
  seed = 12345L
  num_test = m/3
  
  ; sampling with replacement
  test_indices = RANDOMU(seed,num_test,/long) MOD m
  test_indices =  test_indices[SORT(test_indices)]
  train_indices=Difference(LINDGEN(m),test_indices)
  Gs_test = Gs[*,test_indices]
  Ls_test = Ls[*,test_indices]
  m = N_ELEMENTS(train_indices)
  Gs = Gs[*,train_indices]
  Ls = Ls[*,train_indices]
  
  ; train the classifier
  mn =  FLTARR(num_bands,K)
  cov = FLTARR(num_bands,num_bands,K)
  class_names = STRARR(K+1)
  class_names[0]='unclassified'
  void = MAX(TRANSPOSE(Ls),labels,dimension=2)
  labels = BYTE((labels/m))
  FOR i=0,K-1 DO BEGIN
    class_names[i+1]='class'+STRING(i+1)
    indices = WHERE(labels EQ i,count)
    IF count GT 1 THEN BEGIN
      GGs = Gs[*,indices]
      FOR j=0,num_bands-1 DO mn[j,i] = Mean(GGs[j,*])
      cov[*,*,i] = Correlate(GGs,/covariance)
    ENDIF
  ENDFOR
  
  envi_check_save, /classification
  
  lookup = [[0,0,0],[roi_colors[*,ptr]]]
  IF rule_flag THEN BEGIN
    ENVI_DOIT, 'class_doit', fid=fid, dims=dims, $
      pos=pos, out_bname='MaxLike('+fname+')', $
      class_names=class_names, $
      lookup=lookup, $
      method=2, mean=mn, cov=cov, $
      out_name = class_filename, $
      rule_out_name = rule_filename, $
      rule_out_bname=roi_names[ptr]
    PRINT, 'classification file created ', class_filename
    PRINT, 'rule file created ', rule_filename
  END  ELSE  BEGIN
    ENVI_DOIT, 'class_doit', fid=fid, dims=dims, $
      pos=pos, out_bname='MaxLike('+fname+')', $
      class_names=class_names, $
      lookup=lookup, $
      method=2, mean=mn, cov=cov, $
      out_name = class_filename
    PRINT, 'classification file created ', class_filename
  ENDELSE
  
  ; test the classifier
  dummy = FLTARR(1,num_test,num_bands)
  dummy[0,*,*] = TRANSPOSE(Gs_test)
  dummy_dims = [-1L,0,0,0,num_test-1]
  dummy_pos = INDGEN(num_bands)
  ENVI_ENTER_DATA, dummy, r_fid=r_fid
  ENVI_DOIT, 'class_doit', fid=r_fid, r_fid=r_fid1, $
    dims=dummy_dims, pos=dummy_pos, out_bname='Test', $
    class_names=class_names, lookup=lookup, $
    method=2, mean=mn, cov=cov, /in_memory
  test_classes = (ENVI_GET_DATA(fid=r_fid1,pos=0,dims=dummy_dims))[*]
  ENVI_FILE_MNG, id=r_fid,/remove
  ENVI_FILE_MNG, id=r_fid1,/remove
  OPENW,lun,outfile,/get_lun
  PRINTF,lun,'; MaxLike test results for '+ fname
  PRINTF,lun,'; '+SYSTIME(0)
  PRINTF,lun,'; Classification image: '+ class_filename
  PRINTF,lun,'; Class rule image: '+ rule_filename
  PRINTF,lun, num_test, K
  void = MAX(TRANSPOSE(Ls_test),labels,dimension=2)
  labels = BYTE((labels/num_test)+1)
  PRINTF,lun, TRANSPOSE([[test_classes], [labels]])
  FREE_LUN,lun
  PRINT, 'test results written to ' + outfile
  
  ENVI_BATCH_EXIT
  
END