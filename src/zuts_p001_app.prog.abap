*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_APP
*&---------------------------------------------------------------------*
*& Uygulama controller.
*&   - Secim ekrani degerlerini okur
*&   - lcl_service_runner'i orkestre eder
*&   - Servis tipine gore uygun lcl_alv_view display metodunu cagirir
*&---------------------------------------------------------------------*

CLASS lcl_app DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS run.

  PRIVATE SECTION.
    METHODS get_selected_service
      RETURNING VALUE(rv_code) TYPE string.

    METHODS validate_input
      RETURNING VALUE(rv_ok) TYPE abap_bool.

ENDCLASS.


CLASS lcl_app IMPLEMENTATION.

  METHOD get_selected_service.
    rv_code = COND #(
                WHEN p_srv1 = abap_true THEN 'URUN_SORGULAMA'
                WHEN p_srv2 = abap_true THEN 'URUN_KAYIT_GUNCELLE'
                WHEN p_srv3 = abap_true THEN 'ITHALAT_BILDIRIMI'
                WHEN p_srv4 = abap_true THEN 'VERME_BILDIRIMI'
                WHEN p_srv5 = abap_true THEN 'ALMA_BILDIRIMI'
                WHEN p_srv6 = abap_true THEN 'STOK_SORGULAMA' ).
  ENDMETHOD.


  METHOD validate_input.
    rv_ok = abap_true.

    IF p_token IS INITIAL.
      MESSAGE 'JWT Token girilmelidir' TYPE 'I' DISPLAY LIKE 'E'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.

    IF get_selected_service( ) IS INITIAL.
      MESSAGE 'Bir servis secilmelidir' TYPE 'I' DISPLAY LIKE 'E'.
      rv_ok = abap_false.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD run.

    IF validate_input( ) = abap_false.
      RETURN.
    ENDIF.

    DATA(lo_runner) = NEW lcl_service_runner(
                            iv_env   = 'TEST'
                            iv_dest  = p_dest
                            iv_token = p_token ).

    IF lo_runner IS NOT BOUND.
      MESSAGE 'Servis runner olusturulamadi' TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA ls_summary       TYPE lcl_service_runner=>ty_run_result.
    DATA lt_urun_rows     TYPE lcl_service_runner=>tt_urun_rows.
    DATA lt_bildirim_rows TYPE lcl_service_runner=>tt_bildirim_rows.
    DATA lt_stok_rows     TYPE lcl_service_runner=>tt_stok_rows.

    lo_runner->run(
      EXPORTING iv_service_code  = get_selected_service( )
                iv_use_dummy     = p_dummy
      IMPORTING es_summary       = ls_summary
                et_urun_rows     = lt_urun_rows
                et_bildirim_rows = lt_bildirim_rows
                et_stok_rows     = lt_stok_rows ).

    DATA(lo_view) = NEW lcl_alv_view( ).
    IF lo_view IS NOT BOUND.
      MESSAGE 'ALV goruntuleyici olusturulamadi' TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CASE ls_summary-view_type.
      WHEN lcl_service_runner=>c_view-urun.
        lo_view->display_urun(
          EXPORTING is_summary = ls_summary
          CHANGING  ct_rows    = lt_urun_rows ).

      WHEN lcl_service_runner=>c_view-bildirim.
        lo_view->display_bildirim(
          EXPORTING is_summary = ls_summary
          CHANGING  ct_rows    = lt_bildirim_rows ).

      WHEN lcl_service_runner=>c_view-stok.
        lo_view->display_stok(
          EXPORTING is_summary = ls_summary
          CHANGING  ct_rows    = lt_stok_rows ).

      WHEN OTHERS.
        MESSAGE |Tanimsiz view tipi: { ls_summary-view_type }| TYPE 'I' DISPLAY LIKE 'W'.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
