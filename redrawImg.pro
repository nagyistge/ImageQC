;ImageQC - quality control of medical images
;Copyright (C) 2016  Ellen Wasbo, Stavanger University Hospital, Norway
;ellen@wasbo.no
;
;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License version 2
;as published by the Free Software Foundation.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

pro redrawImg, viewpl, newActive

  COMMON VARI

  WIDGET_CONTROL, /HOURGLASS
  WIDGET_CONTROL, drawLarge, GET_VALUE = iDrawLarge
  oModel=OBJ_NEW('IDLgrModel')
  
  tags=TAG_NAMES(structImgs)
  IF tags(0) NE 'EMPTY' THEN BEGIN
    
    curMode=WIDGET_INFO(wTabModes, /TAB_CURRENT)
    sel=WIDGET_INFO(listFiles, /LIST_SELECT)  & sel=sel(0)

    IF nFrames NE 0 THEN BEGIN
      tempStruct=structImgs.(0)
      IF newActive THEN activeImg=readImg(structImgs.(0).filename, sel)
      nImg=nFrames
    ENDIF ELSE BEGIN
      tempStruct=structImgs.(sel)
      IF newActive THEN activeImg=readImg(structImgs.(sel).filename, 0)
      nImg=N_TAGS(structImgs)
    ENDELSE
    sizeAct=SIZE(activeImg, /DIMENSIONS)
    tempAct=activeImg

    maxSz=max(sizeAct[0:1])
    IF N_ELEMENTS(viewpl) EQ 1 THEN viewpl=[0.,0.,maxSz,maxSz];[0.,0.,sizeAct[0:1]]
    oView=OBJ_NEW('IDLgrView', VIEWPLANE_RECT =viewpl)
    
    imgCenterOffset=[0,0,0,0]
    IF dxya(3) EQ 1 THEN imgCenterOffset=dxya
       
    ;display Img
    WIDGET_CONTROL, txtMinWL, GET_VALUE=lower
    WIDGET_CONTROL, txtMaxWL, GET_VALUE=upper
    rangeWL=LONG([lower,upper])
    tempAct=adjustWindowLevel(tempAct, rangeWL)
    
    oPaletteCT=OBJ_NEW('IDLgrPalette')
    oPaletteCT->LoadCT, 0
    oImageCT = OBJ_NEW('IDLgrImage', tempAct, /GREYSCALE)
    oModel->Add, oImageCT
    
    mmCT=tempStruct.pix*sizeAct
    
    IF nFrames EQ 0 THEN BEGIN
      fileList=getListOpenFiles(structImgs,0,marked)
      IF tempStruct.modality EQ 'CT' THEN textZpos='z = '+ STRING(tempStruct.zpos,FORMAT='(f0.3)') ELSE textZpos ='' 
    ENDIF ELSE BEGIN
      fileList=getListFrames(structImgs.(0), marked)
      textZpos='z = '+ STRING(structImgs.(0).zPos(sel),FORMAT='(f0.3)')
    ENDELSE
    
    oTextZ = OBJ_NEW('IDLgrText', textZpos, LOCATIONS = [2,20], COLOR = 255*([1,0,0]))
    oModel->Add, oTextZ
    
    textAdr=STRMID(fileList(sel),2)
    oTextAdr = OBJ_NEW('IDLgrText', textAdr, LOCATIONS = [2,2], COLOR = 255*([1,0,0]))
    oModel->Add, oTextAdr
    
    lineX= OBJ_NEW('IDLgrPolyline', COLOR = 255*([1,0,0]), LINESTYLE=1)
    lineY= OBJ_NEW('IDLgrPolyline', COLOR = 255*([1,0,0]), LINESTYLE=1)
    
    IF analyse EQ 'ROI' THEN BEGIN; ROI
      RESTORE, thisPath + 'data\thisROI.sav'
      oModel->Add, thisROI
    ENDIF
    
    IF analyse EQ 'CTLIN' OR analyse EQ 'HOMOG' OR analyse EQ 'NOISE' OR analyse EQ 'STP' OR analyse EQ 'CONTRAST' THEN BEGIN
      CASE analyse OF 
      'CTLIN': ROIs=CTlinROIs
      'HOMOG': ROIs=homogROIs
      'NOISE': ROIs=noiseROI
      'STP': ROIs=stpROI
      'CONTRAST': ROIs=conROIs
      ELSE:
      ENDCASE
      contour0=OBJ_NEW('IDLgrContour',ROIs[*,*,0],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
      oModel->Add, Contour0
      IF analyse EQ 'CTLIN' OR analyse EQ 'HOMOG' OR analyse EQ 'CONTRAST' THEN BEGIN
        contour1=OBJ_NEW('IDLgrContour',ROIs[*,*,1],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        contour2=OBJ_NEW('IDLgrContour',ROIs[*,*,2],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        contour3=OBJ_NEW('IDLgrContour',ROIs[*,*,3],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        contour4=OBJ_NEW('IDLgrContour',ROIs[*,*,4],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        oModel->Add, Contour1 & oModel->Add, Contour2 & oModel->Add, Contour3 & oModel->Add, Contour4
      ENDIF
      IF analyse EQ 'CTLIN' OR analyse EQ 'CONTRAST' THEN BEGIN
        contour5=OBJ_NEW('IDLgrContour',ROIs[*,*,5],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        contour6=OBJ_NEW('IDLgrContour',ROIs[*,*,6],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        oModel->Add, Contour5 & oModel->Add, Contour6
      ENDIF
      IF analyse EQ 'CTLIN' THEN BEGIN
        contour7=OBJ_NEW('IDLgrContour',ROIs[*,*,7],COLOR=255*([1,0,0]), C_VALUE=0.5, N_LEVELS=1)
        oModel->Add, Contour7
      ENDIF
    ENDIF
    
    IF analyse EQ 'SLICETHICK' THEN BEGIN; slice thickness ramps
      
      WIDGET_CONTROL, txtRampDist, GET_VALUE=rampDist
      rampDist=ROUND(FLOAT(rampDist(0))/tempStruct.pix(0)) ; assume x,y pix equal ! = normal
      WIDGET_CONTROL, txtRampLen, GET_VALUE=len
      len=ROUND(FLOAT(len(0))/tempStruct.pix(0)) ; assume x,y pix equal ! = normal
      WIDGET_CONTROL, cw_ramptype, GET_VALUE=ramptype 
      
      Case ramptype OF
        0: ramps=getRamps(sizeAct, imgCenterOffset, rampDist, len)
        1: BEGIN
          ramps=getRamps(sizeAct, imgCenterOffset, 45./tempStruct.pix(0), len)
          ramps2=getRamps(sizeAct, imgCenterOffset, 25./tempStruct.pix(0), len)
          END
      Endcase

      WIDGET_CONTROL, txtRampSearch, GET_VALUE=nRamps
      nRamps=LONG(nRamps(0))
      
      H1=OBJ_NEW('IDLgrPolyline', [ramps[0,0],ramps[2,0]],[ramps[1,0]+nRamps,ramps[3,0]+nRamps], COLOR = 255*([1,0,0]), LINESTYLE=0)
      H1_1=OBJ_NEW('IDLgrPolyline', [ramps[0,0],ramps[2,0]],[ramps[1,0]-nRamps,ramps[3,0]-nRamps], COLOR = 255*([1,0,0]), LINESTYLE=0)
      H2=OBJ_NEW('IDLgrPolyline', [ramps[0,1],ramps[2,1]],[ramps[1,1]+nRamps,ramps[3,1]+nRamps], COLOR = 255*([0,1,0]), LINESTYLE=0)
      H2_1=OBJ_NEW('IDLgrPolyline', [ramps[0,1],ramps[2,1]],[ramps[1,1]-nRamps,ramps[3,1]-nRamps], COLOR = 255*([0,1,0]), LINESTYLE=0)
      V1=OBJ_NEW('IDLgrPolyline', [ramps[0,2]+nRamps,ramps[2,2]+nRamps],[ramps[1,2],ramps[3,2]], COLOR = 255*([0,0,1]), LINESTYLE=0)
      V1_1=OBJ_NEW('IDLgrPolyline', [ramps[0,2]-nRamps,ramps[2,2]-nRamps],[ramps[1,2],ramps[3,2]], COLOR = 255*([0,0,1]), LINESTYLE=0)
      V2=OBJ_NEW('IDLgrPolyline', [ramps[0,3]+nRamps,ramps[2,3]+nRamps],[ramps[1,3],ramps[3,3]], COLOR = 255*([1,1,1]), LINESTYLE=0)
      V2_1=OBJ_NEW('IDLgrPolyline', [ramps[0,3]-nRamps,ramps[2,3]-nRamps],[ramps[1,3],ramps[3,3]], COLOR = 255*([1,1,1]), LINESTYLE=0)
      oModel->Add, H1 & oModel->Add, H1_1 & oModel->Add, H2 & oModel->Add, H2_1 & oModel->Add, V1 & oModel->Add, V1_1 & oModel->Add, V2 & oModel->Add, V2_1
      IF  ramptype EQ 1 THEN BEGIN
        V3=OBJ_NEW('IDLgrPolyline', [ramps2[0,2]+nRamps,ramps2[2,2]+nRamps],[ramps2[1,2],ramps2[3,2]], COLOR = 255*([1,0,1]), LINESTYLE=0)
        V3_1=OBJ_NEW('IDLgrPolyline', [ramps2[0,2]-nRamps,ramps2[2,2]-nRamps],[ramps2[1,2],ramps2[3,2]], COLOR = 255*([1,0,1]), LINESTYLE=0)
        V4=OBJ_NEW('IDLgrPolyline', [ramps2[0,3]+nRamps,ramps2[2,3]+nRamps],[ramps2[1,3],ramps2[3,3]], COLOR = 255*([0,1,1]), LINESTYLE=0)
        V4_1=OBJ_NEW('IDLgrPolyline', [ramps2[0,3]-nRamps,ramps2[2,3]-nRamps],[ramps2[1,3],ramps2[3,3]], COLOR = 255*([0,1,1]), LINESTYLE=0)
        oModel->Add, V3 & oModel->Add, V3_1 & oModel->Add, V4 & oModel->Add, V4_1
      ENDIF
    ENDIF

    markedArr=INTARR(nImg)
    IF marked(0) EQ -1 THEN markedArr=markedArr+1 ELSE markedArr(marked)=1
    IF analyse EQ 'DIM' AND N_ELEMENTS(dimRes) GT 1 AND markedArr(sel) EQ 1 THEN BEGIN; linear dimensions - rod positions
      posX=dimRes[6:9, sel]+sizeAct(0)/2+imgCenterOffset(0)
      posY=dimRes[10:13, sel]+sizeAct(1)/2+imgCenterOffset(1)
      dimLine=OBJ_NEW('IDLgrPolyline', [[posX(0),posY(0)],[posX(1),posY(1)],[posX(2),posY(2)],[posX(3),posY(3)],[posX(0),posY(0)]], COLOR = 255*([1,0,0]), /DOUBLE, LINESTYLE=0)
      oModel->Add, dimLine ;& oModel->Add, H2 & oModel->Add, V1 & oModel->Add, V2 & oModel->Add, D1 & oModel->Add, D2
    ENDIF
    
    IF analyse EQ 'FWHM' THEN BEGIN
      center=sizeAct/2+imgCenterOffset[0:1]
      centerB=center
      centerB(1)=sizeAct(1)-center(1)
      fwhmLine=OBJ_NEW('IDLgrPolyline', [[center(0)-15,center(1)-5],[center(0)-15,center(1)+4],[center(0)+15,center(1)+4],[center(0)+15,center(1)-5],[center(0)-15,center(1)-5]], COLOR = 255*([1,0,0]), /DOUBLE, LINESTYLE=0)
      fwhmBackLine=OBJ_NEW('IDLgrPolyline', [[centerB(0)-15,centerB(1)-5],[centerB(0)-15,centerB(1)+4],[centerB(0)+15,centerB(1)+4],[centerB(0)+15,centerB(1)-5],[centerB(0)-15,centerB(1)-5]], COLOR = 255*([1,0,0]), /DOUBLE, LINESTYLE=0)
      oModel->Add, fwhmLine & oModel->Add, fwhmBackLine
      oTextBG = OBJ_NEW('IDLgrText', 'Background', LOCATIONS = [centerB(0)+20,centerB(1)], COLOR = 255*([1,0,0]))
      oModel->Add, oTextBG
    ENDIF
    
    IF analyse EQ 'SCANSPEED' THEN BEGIN
      WIDGET_CONTROL, txtNAvgSpeedNM, GET_VALUE=val
      val=LONG(val(0))
      val=val/2-1
      IF val LT 0 THEN val=0
      WIDGET_CONTROL, txtSpeedROIheight, GET_VALUE=valh
      height=FLOAT(valh(0))*10./tempstruct.pix(1)
      IF dxya(1)+sizeAct(1)/2 GE height/2 THEN first=dxya(1)+sizeAct(1)/2-height/2 ELSE first=0
      IF dxya(1)+sizeAct(1)/2+height/2 LT sizeAct(1)-1 THEN last=dxya(1)+sizeAct(1)/2+height/2 ELSE last=sizeAct(1)-1
      posX=sizeAct(0)/2+dxya(0)
      speedLine=OBJ_NEW('IDLgrPolyline', [[posX-val,first],[posX-val,last],[posX+val,last],[posX+val,first],[posX-val,first]], COLOR = 255*([1,0,0]), /DOUBLE, LINESTYLE=0)
      oModel->Add, speedLine
    ENDIF
    
    halfSz=sizeAct/2
    IF dxya(3) EQ 1 THEN BEGIN
      tana=TAN(dxya(2)*!DtoR)
      dy1=tana*(halfSz(0)+dxya(0))
      dy2=tana*(halfSz(0)-dxya(0))
      dx1=tana*(halfSz(1)+dxya(1))
      dx2=tana*(halfSz(1)-dxya(1))
      lineX->SetProperty, DATA=[[0,halfSz(1)+dxya(1)+dy1],[sizeAct(0),halfSz(1)+dxya(1)-dy2]]
      lineY->SetProperty, DATA=[[halfSz(0)+dxya(0)-dx1,0],[halfSz(0)+dxya(0)+dx2,sizeAct(1)]]
      IF analyse EQ 'MTF' THEN BEGIN; dxya(2) = 0 & dxya(3)=1
        CASE curMode OF
          
        0: BEGIN;CT
          WIDGET_CONTROL, txtMTFroiSz, GET_VALUE=ROIsz
          ROIsz=ROUND(ROIsz(0)/tempStruct.pix)
          x1=halfSz(0)+dxya(0)-ROIsz(0) & x2=halfSz(0)+dxya(0)+ROIsz(0)
          y1=halfSz(1)+dxya(1)-ROIsz(0) & y2=halfSz(1)+dxya(1)+ROIsz(0)
          lineROI = OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=0)
          oModel->Add, lineROI
          WIDGET_CONTROL, cw_typeMTF, GET_VALUE=typeMTF
          IF typeMTF EQ 0 THEN BEGIN
            y1=y1-(ROIsz(0)*2+1) & y2=y2-(ROIsz(0)*2+1)
            lineROI2 = OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=0)
            oModel->Add, lineROI2
            oTextBG = OBJ_NEW('IDLgrText', 'Background', LOCATIONS = [x1,y1], COLOR = 255*([1,0,0]))
            oModel->Add, oTextBG
          ENDIF
        END
        1: BEGIN;xray
            WIDGET_CONTROL, txtMTFroiSzX, GET_VALUE=ROIszX
            WIDGET_CONTROL, txtMTFroiSzY, GET_VALUE=ROIszY
            ROIsz=ROUND([ROIszX(0),ROIszY(0)]/(2.*tempStruct.pix))
            x1=halfSz(0)+dxya(0)-ROIsz(0) & x2=halfSz(0)+dxya(0)+ROIsz(0)
            y1=halfSz(1)+dxya(1)-ROIsz(1) & y2=halfSz(1)+dxya(1)+ROIsz(1)
            lineROI = OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=0)
            oModel->Add, lineROI
        END
        2: BEGIN;NM
          WIDGET_CONTROL, txtMTFroiSzXNM, GET_VALUE=ROIszX
          WIDGET_CONTROL, txtMTFroiSzYNM, GET_VALUE=ROIszY
          ROIsz=ROUND([ROIszX(0),ROIszY(0)]/(2.*tempStruct.pix))
          x1=halfSz(0)+dxya(0)-ROIsz(0) & x2=halfSz(0)+dxya(0)+ROIsz(0)
          y1=halfSz(1)+dxya(1)-ROIsz(1) & y2=halfSz(1)+dxya(1)+ROIsz(1)
          lineROI = OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=0)
          oModel->Add, lineROI
        END
        ELSE:
        ENDCASE
      ENDIF
      IF analyse EQ 'NPS' THEN BEGIN
        CASE curMode OF
          0: BEGIN
            WIDGET_CONTROL, txtNPSroiSz, GET_VALUE=ROIsz
            WIDGET_CONTROL, txtNPSroiDist, GET_VALUE=ROIdist
            WIDGET_CONTROL, txtNPSsubNN, GET_VALUE=subNN
            contour0=OBJ_NEW('IDLgrContour',total(NPSrois,3),COLOR=255*([1,0,0]), C_VALUE=[1,2,3,4])
            oModel->Add, Contour0
            END
          1: BEGIN
            WIDGET_CONTROL, txtNPSroiSzX, GET_VALUE=ROIsz
            WIDGET_CONTROL, txtNPSsubSzX, GET_VALUE=subSz
            ROIsz=LONG(ROIsz(0)) & subSz=LONG(subSz(0))
            x1=halfSz(0)+dxya(0)-ROIsz*subSz*0.5 & x2=halfSz(0)+dxya(0)+ROIsz*subSz*0.5
            y1=halfSz(1)+dxya(1)-ROIsz*subSz*0.5 & y2=halfSz(1)+dxya(1)+ROIsz*subSz*0.5
            lineROI = OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=0)
            oModel->Add, lineROI
            x1=halfSz(0)+dxya(0)-ROIsz*0.5 & x2=halfSz(0)+dxya(0)+ROIsz*0.5
            y1=halfSz(1)+dxya(1)-ROIsz*0.5 & y2=halfSz(1)+dxya(1)+ROIsz*0.5
            lineROI2 = OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=0)
            oModel->Add, lineROI2
            x1=halfSz(0)+dxya(0) & x2=halfSz(0)+dxya(0)+ROIsz
            y1=halfSz(1)+dxya(1) & y2=halfSz(1)+dxya(1)+ROIsz
            lineROI3= OBJ_NEW('IDLgrPolyline', [[x1,y1],[x2,y1],[x2,y2],[x1,y2],[x1,y1]], COLOR = 255*([1,0,0]), LINESTYLE=1)
            oModel->Add, lineROI3
            END
          2:
        ENDCASE

      ENDIF
    ENDIF ELSE BEGIN
      lineX->SetProperty, DATA=[[0,halfSz(1)],[sizeAct(0)-1,halfSz(1)]]
      lineY->SetProperty, DATA=[[halfSz(0),0],[halfSz(0),sizeAct(1)-1]]
    ENDELSE
    
    oModel->Add, lineX & oModel->Add, lineY
    
    oView->Add,oModel
    
    iDrawLarge->Draw,oView
    
     OBJ_DESTROY, oPaletteCT & OBJ_DESTROY, oTextZ & OBJ_DESTROY, oTextAdr & OBJ_DESTROY,lineX & OBJ_DESTROY,lineY
    
    IF OBJ_VALID(contour0) THEN BEGIN
      OBJ_DESTROY, contour0
      IF OBJ_VALID(contour1) THEN BEGIN
        OBJ_DESTROY, contour1 &  OBJ_DESTROY, contour2 & OBJ_DESTROY, contour3 & OBJ_DESTROY, contour4
      ENDIF
      IF OBJ_VALID(contour5) THEN BEGIN
        OBJ_DESTROY, contour5 &  OBJ_DESTROY, contour6        
      ENDIF
      IF OBJ_VALID(contour7) THEN OBJ_DESTROY, contour7
    ENDIF
    
    IF OBJ_VALID(lineROI) THEN BEGIN;2?
      OBJ_DESTROY, lineROI
      IF OBJ_VALID(lineROI2) THEN BEGIN
        OBJ_DESTROY, lineROI2
        IF OBJ_VALID(lineROI3) THEN OBJ_DESTROY, lineROI3
      ENDIF
    ENDIF
    
    IF OBJ_VALID(H1) THEN BEGIN
      OBJ_DESTROY, H1 & OBJ_DESTROY, H1_1 & OBJ_DESTROY, H2 & OBJ_DESTROY, H2_1 &  OBJ_DESTROY, V1 &  OBJ_DESTROY, V1_1 & OBJ_DESTROY, V2 & OBJ_DESTROY, V2_1
      ;IF OBJ_VALID(D1) THEN BEGIN
      ;  OBJ_DESTROY, D1 & OBJ_DESTROY, D2
      ;  ENDIF
      IF OBJ_VALID(V3) THEN BEGIN
        OBJ_DESTROY, V3 &  OBJ_DESTROY, V3_1 & OBJ_DESTROY, V4 & OBJ_DESTROY, V4_1
      ENDIF
    ENDIF
    
    IF OBJ_VALID(dimLine) THEN OBJ_DESTROY, dimLine
    IF OBJ_VALID(fwhmLine) THEN OBJ_DESTROY, fwhmLine
    IF OBJ_VALID(fwhmBackLine) THEN OBJ_DESTROY, fwhmBackLine
    IF OBJ_VALID(speedLine) THEN OBJ_DESTROY, speedLine
    
   ENDIF ELSE BEGIN
    oView=OBJ_NEW('IDLgrView', VIEWPLANE_RECT =[0.,0.,550,550])
    oImageCT = OBJ_NEW('IDLgrImage', INTARR(550,550), /GREYSCALE)
    oModel->Add, oImageCT
    oView->Add,oModel
    iDrawLarge->Draw,oView
    
   ENDELSE
   OBJ_DESTROY, oView & OBJ_DESTROY, oModel & OBJ_DESTROY, oImageCT
  
end