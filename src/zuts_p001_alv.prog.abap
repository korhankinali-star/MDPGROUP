*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_ALV
*&---------------------------------------------------------------------*
*& Servis cagri sonuclarini SALV tablosu olarak goruntuler.
*&
*& Dikkat: CL_SALV_TABLE=>FACTORY, CHANGING parametresinde tipli bir
*& tablo bekler. Bu yuzden display metodu generic STANDARD TABLE yerine
*& LCL_SERVICE_RUNNER=>TT_RUN_RESULTS referans tipi alir.
*&---------------------------------------------------------------------*

CLASS lcl_alv_view DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS display
      CHANGING
        !ct_results TYPE lcl_service_runner=>tt_run_results.

  PRIVATE SECTION.
    METHODS configure_columns
      IMPORTING
        !io_alv TYPE REF TO cl_salv_table
      RAISING
        cx_salv_not_found.

    METHODS configure_functions
      IMPORTING
        !io_alv TYPE REF TO cl_salv_table.

    METHODS configure_settings
      IMPORTING
        !io_alv TYPE REF TO cl_salv_table.

ENDCLASS.


CLASS lcl_alv_view IMPLEMENTATION.

  METHOD display.

    DATA lo_alv TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = ct_results ).

        IF lo_alv IS NOT BOUND.
          MESSAGE 'ALV olusturulamadi' TYPE 'I'.
          RETURN.
        ENDIF.

        configure_functions( lo_alv ).
        configure_settings(  lo_alv ).
        configure_columns(   lo_alv ).

        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_salv_msg).
        MESSAGE lx_salv_msg->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
      CATCH cx_salv_not_found INTO DATA(lx_salv_nf).
        MESSAGE lx_salv_nf->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
    ENDTRY.

  ENDMETHOD.


  METHOD configure_functions.
    DATA lo_func TYPE REF TO cl_salv_functions_list.

    lo_func = io_alv->get_functions( ).
    IF lo_func IS BOUND.
      lo_func->set_all( abap_true ).
    ENDIF.
  ENDMETHOD.


  METHOD configure_settings.
    DATA lo_settings TYPE REF TO cl_salv_display_settings.

    lo_settings = io_alv->get_display_settings( ).
    IF lo_settings IS BOUND.
      lo_settings->set_striped_pattern( abap_true ).
      lo_settings->set_list_header( 'UTS Servis Test Sonucu' ).
    ENDIF.
  ENDMETHOD.


  METHOD configure_columns.

    DATA lo_cols TYPE REF TO cl_salv_columns_table.
    DATA lo_col  TYPE REF TO cl_salv_column_table.

    lo_cols = io_alv->get_columns( ).
    IF lo_cols IS NOT BOUND.
      RETURN.
    ENDIF.

    lo_cols->set_optimize( abap_true ).

    " Durum ikonu
    lo_col ?= lo_cols->get_column( 'SUCCESS_ICON' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Durum' ).
      lo_col->set_medium_text( 'Durum' ).
      lo_col->set_long_text( 'Durum' ).
    ENDIF.

    " Servis Adi
    lo_col ?= lo_cols->get_column( 'SERVICE_NAME' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Servis' ).
      lo_col->set_medium_text( 'Servis' ).
      lo_col->set_long_text( 'Servis Adi' ).
    ENDIF.

    " Servis Kodu - gizle
    lo_col ?= lo_cols->get_column( 'SERVICE_CODE' ).
    IF lo_col IS BOUND.
      lo_col->set_visible( abap_false ).
    ENDIF.

    " Endpoint
    lo_col ?= lo_cols->get_column( 'ENDPOINT' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Endpoint' ).
      lo_col->set_medium_text( 'Endpoint' ).
      lo_col->set_long_text( 'Endpoint URI' ).
    ENDIF.

    " HTTP Status
    lo_col ?= lo_cols->get_column( 'HTTP_STATUS' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'HTTP' ).
      lo_col->set_medium_text( 'HTTP Kodu' ).
      lo_col->set_long_text( 'HTTP Durum Kodu' ).
    ENDIF.

    " Success flag - gizle (icon zaten goruntulenir)
    lo_col ?= lo_cols->get_column( 'SUCCESS_FLAG' ).
    IF lo_col IS BOUND.
      lo_col->set_visible( abap_false ).
    ENDIF.

    " Duration
    lo_col ?= lo_cols->get_column( 'DURATION_MS' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Sure ms' ).
      lo_col->set_medium_text( 'Sure (ms)' ).
      lo_col->set_long_text( 'Cagri Suresi (ms)' ).
    ENDIF.

    " Request JSON
    lo_col ?= lo_cols->get_column( 'REQUEST_JSON' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Istek' ).
      lo_col->set_medium_text( 'Istek JSON' ).
      lo_col->set_long_text( 'Istek JSON' ).
    ENDIF.

    " Response JSON
    lo_col ?= lo_cols->get_column( 'RESPONSE_JSON' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Cevap' ).
      lo_col->set_medium_text( 'Cevap JSON' ).
      lo_col->set_long_text( 'Cevap JSON' ).
    ENDIF.

    " Error Message
    lo_col ?= lo_cols->get_column( 'ERROR_MSG' ).
    IF lo_col IS BOUND.
      lo_col->set_short_text( 'Hata' ).
      lo_col->set_medium_text( 'Hata Mesaji' ).
      lo_col->set_long_text( 'Hata Mesaji' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
