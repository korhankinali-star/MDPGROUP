*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_APP
*&---------------------------------------------------------------------*
*& Uygulama controller.
*&   - Secim ekrani degerlerini okur
*&   - lcl_service_runner'i orkestre eder
*&   - lcl_alv_view ile sonucu gosterir
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

    DATA(ls_result) = lo_runner->run(
                        iv_service_code = get_selected_service( )
                        iv_use_dummy    = p_dummy ).

    DATA lt_results TYPE lcl_service_runner=>tt_run_results.
    APPEND ls_result TO lt_results.

    DATA(lo_view) = NEW lcl_alv_view( ).
    IF lo_view IS NOT BOUND.
      MESSAGE 'ALV goruntuleyici olusturulamadi' TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    lo_view->display( CHANGING ct_results = lt_results ).

  ENDMETHOD.

ENDCLASS.
