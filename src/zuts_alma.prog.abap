REPORT zuts_alma.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS:
  p_token TYPE string LOWER CASE.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS:
  p_vbi  TYPE char40,
  p_udi  TYPE char50,
  p_uno  TYPE char23,
  p_lno  TYPE char20,
  p_sno  TYPE char20,
  p_adt  TYPE i,
  p_gkk  TYPE i.
SELECTION-SCREEN END OF BLOCK b2.

START-OF-SELECTION.

  DATA: lo_client   TYPE REF TO zcl_uts_client,
        lv_json     TYPE string,
        lv_first    TYPE abap_bool,
        lv_response TYPE string,
        lv_status   TYPE i.

  lv_json  = |\{|.
  lv_first = abap_true.

  IF p_vbi IS NOT INITIAL.
    lv_json = lv_json && |"VBI":"{ p_vbi }"|.
    lv_first = abap_false.
  ENDIF.

  IF p_udi IS NOT INITIAL.
    IF lv_first = abap_false. lv_json = lv_json && |,|. ENDIF.
    lv_json = lv_json && |"UDI":"{ p_udi }"|.
    lv_first = abap_false.
  ENDIF.

  IF p_uno IS NOT INITIAL.
    IF lv_first = abap_false. lv_json = lv_json && |,|. ENDIF.
    lv_json = lv_json && |"UNO":"{ p_uno }"|.
    lv_first = abap_false.
  ENDIF.

  IF p_lno IS NOT INITIAL.
    IF lv_first = abap_false. lv_json = lv_json && |,|. ENDIF.
    lv_json = lv_json && |"LNO":"{ p_lno }"|.
    lv_first = abap_false.
  ENDIF.

  IF p_sno IS NOT INITIAL.
    IF lv_first = abap_false. lv_json = lv_json && |,|. ENDIF.
    lv_json = lv_json && |"SNO":"{ p_sno }"|.
    lv_first = abap_false.
  ENDIF.

  IF p_adt IS NOT INITIAL.
    IF lv_first = abap_false. lv_json = lv_json && |,|. ENDIF.
    lv_json = lv_json && |"ADT":{ p_adt }|.
    lv_first = abap_false.
  ENDIF.

  IF p_gkk IS NOT INITIAL.
    IF lv_first = abap_false. lv_json = lv_json && |,|. ENDIF.
    lv_json = lv_json && |"GKK":{ p_gkk }|.
  ENDIF.

  lv_json = lv_json && |\}|.

  TRY.
      CREATE OBJECT lo_client
        EXPORTING iv_dest = 'ZUTS_TEST'.

      lo_client->alma_bildirimi(
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
    MESSAGE 'Alma bildirimi basariyla gonderildi' TYPE 'S'.
  ELSE.
    MESSAGE |UTS hata dondu: { lv_status }| TYPE 'I'.
  ENDIF.
