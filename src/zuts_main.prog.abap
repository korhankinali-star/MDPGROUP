REPORT zuts_main.

*----------------------------------------------------------------------*
* UTS - Verme Bildirimi (Essiz Kimlik)
*----------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS:
  p_token TYPE string LOWER CASE.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS:
  p_uno  TYPE char23  OBLIGATORY,
  p_lno  TYPE char20,
  p_sno  TYPE char20,
  p_adt  TYPE i,
  p_kun  TYPE i       OBLIGATORY,
  p_ben  TYPE char5   DEFAULT 'HAYIR',
  p_bno  TYPE char50  OBLIGATORY,
  p_git  TYPE dats    DEFAULT sy-datum.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
START-OF-SELECTION.

  DATA: lo_client   TYPE REF TO zcl_uts_client,
        lv_json     TYPE string,
        lv_git      TYPE string,
        lv_response TYPE string,
        lv_status   TYPE i.

  IF p_git IS NOT INITIAL.
    lv_git = |{ p_git+0(4) }-{ p_git+4(2) }-{ p_git+6(2) }|.
  ENDIF.

  lv_json = |\{"UNO":"{ p_uno }"|.

  IF p_lno IS NOT INITIAL.
    lv_json = lv_json && |,"LNO":"{ p_lno }"|.
  ENDIF.

  IF p_sno IS NOT INITIAL.
    lv_json = lv_json && |,"SNO":"{ p_sno }"|.
  ENDIF.

  IF p_adt IS NOT INITIAL.
    lv_json = lv_json && |,"ADT":{ p_adt }|.
  ENDIF.

  lv_json = lv_json && |,"KUN":{ p_kun }|.
  lv_json = lv_json && |,"BEN":"{ p_ben }"|.
  lv_json = lv_json && |,"BNO":"{ p_bno }"|.

  IF lv_git IS NOT INITIAL.
    lv_json = lv_json && |,"GIT":"{ lv_git }"|.
  ENDIF.

  lv_json = lv_json && |\}|.

  TRY.
      CREATE OBJECT lo_client
        EXPORTING iv_dest = 'ZUTS_TEST'.

      lo_client->verme_bildirimi(
        EXPORTING iv_token    = p_token
                  iv_json     = lv_json
        IMPORTING ev_response = lv_response
                  ev_status   = lv_status ).

    CATCH cx_root INTO DATA(lo_ex).
      MESSAGE lo_ex->get_text( ) TYPE 'E'.
  ENDTRY.

  WRITE: / 'Gonderilen JSON:', lv_json.
  SKIP.
  WRITE: / 'HTTP Status:', lv_status.
  WRITE: / 'Cevap:'.
  WRITE: / lv_response.

  IF lv_status BETWEEN 200 AND 299.
    MESSAGE 'Verme bildirimi basariyla gonderildi' TYPE 'S'.
  ELSE.
    MESSAGE |UTS hata dondu: { lv_status }| TYPE 'I'.
  ENDIF.
