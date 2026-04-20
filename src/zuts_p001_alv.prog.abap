*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_ALV
*&---------------------------------------------------------------------*
*& Servis cagri sonuclarini SALV tablosu olarak goruntuler.
*&
*& Gosterilen kolonlar:
*&   - Durum ikonu, Servis adi, HTTP kodu, Cagri suresi
*&   - Parse edilmis response alanlari (Sonuc kodu, mesaj, SNC ID,
*&     mesaj tipi, detay sayisi)
*&   - Endpoint, Hata mesaji
*&
*& Gizlenen kolonlar:
*&   - SERVICE_CODE, SUCCESS_FLAG (teknik alanlar)
*&   - RESPONSE_JSON (ham cevap - istenirse kullanici tarafindan ALV
*&     yerlesiminden aktif edilebilir)
*&   - Gonderilen istek (request) ALV'de yer almaz
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

    METHODS set_column_text
      IMPORTING
        !io_cols   TYPE REF TO cl_salv_columns_table
        !iv_name   TYPE lvc_fname
        !iv_short  TYPE scrtext_s
        !iv_medium TYPE scrtext_m
        !iv_long   TYPE scrtext_l
        !iv_hide   TYPE abap_bool DEFAULT abap_false.

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


  METHOD set_column_text.
    DATA lo_col TYPE REF TO cl_salv_column_table.

    TRY.
        lo_col ?= io_cols->get_column( iv_name ).
        IF lo_col IS NOT BOUND.
          RETURN.
        ENDIF.

        IF iv_hide = abap_true.
          lo_col->set_visible( abap_false ).
          RETURN.
        ENDIF.

        lo_col->set_short_text(  iv_short  ).
        lo_col->set_medium_text( iv_medium ).
        lo_col->set_long_text(   iv_long   ).
      CATCH cx_salv_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD configure_columns.

    DATA lo_cols TYPE REF TO cl_salv_columns_table.

    lo_cols = io_alv->get_columns( ).
    IF lo_cols IS NOT BOUND.
      RETURN.
    ENDIF.

    lo_cols->set_optimize( abap_true ).

    " --- Gorunen kolonlar ---
    set_column_text( io_cols = lo_cols iv_name = 'SUCCESS_ICON'
                     iv_short = 'Durum'
                     iv_medium = 'Durum'
                     iv_long = 'Durum' ).

    set_column_text( io_cols = lo_cols iv_name = 'SERVICE_NAME'
                     iv_short = 'Servis'
                     iv_medium = 'Servis'
                     iv_long = 'Servis Adi' ).

    set_column_text( io_cols = lo_cols iv_name = 'HTTP_STATUS'
                     iv_short = 'HTTP'
                     iv_medium = 'HTTP Kodu'
                     iv_long = 'HTTP Durum Kodu' ).

    set_column_text( io_cols = lo_cols iv_name = 'DURATION_MS'
                     iv_short = 'Sure ms'
                     iv_medium = 'Sure (ms)'
                     iv_long = 'Cagri Suresi (ms)' ).

    set_column_text( io_cols = lo_cols iv_name = 'SONUC_KODU'
                     iv_short = 'Sonuc'
                     iv_medium = 'Sonuc Kodu'
                     iv_long = 'Sonuc Kodu' ).

    set_column_text( io_cols = lo_cols iv_name = 'SONUC_MESAJI'
                     iv_short = 'Mesaj'
                     iv_medium = 'Sonuc Mesaji'
                     iv_long = 'Sonuc Mesaji' ).

    set_column_text( io_cols = lo_cols iv_name = 'SNC_ID'
                     iv_short = 'SNC ID'
                     iv_medium = 'Bildirim ID'
                     iv_long = 'Bildirim ID (SNC)' ).

    set_column_text( io_cols = lo_cols iv_name = 'MESAJ_TIPI'
                     iv_short = 'Tip'
                     iv_medium = 'Mesaj Tipi'
                     iv_long = 'Mesaj Tipi (BILGI/HATA)' ).

    set_column_text( io_cols = lo_cols iv_name = 'DETAY_SAYISI'
                     iv_short = 'Detay'
                     iv_medium = 'Detay Sayisi'
                     iv_long = 'Donen Kayit Sayisi' ).

    set_column_text( io_cols = lo_cols iv_name = 'ERROR_MSG'
                     iv_short = 'Hata'
                     iv_medium = 'Hata Mesaji'
                     iv_long = 'Hata Mesaji' ).

    set_column_text( io_cols = lo_cols iv_name = 'ENDPOINT'
                     iv_short = 'Endpoint'
                     iv_medium = 'Endpoint'
                     iv_long = 'Endpoint URI' ).

    " --- Gizlenen kolonlar ---
    set_column_text( io_cols = lo_cols iv_name = 'SERVICE_CODE'
                     iv_short = '' iv_medium = '' iv_long = ''
                     iv_hide = abap_true ).

    set_column_text( io_cols = lo_cols iv_name = 'SUCCESS_FLAG'
                     iv_short = '' iv_medium = '' iv_long = ''
                     iv_hide = abap_true ).

    set_column_text( io_cols = lo_cols iv_name = 'RESPONSE_JSON'
                     iv_short = '' iv_medium = '' iv_long = ''
                     iv_hide = abap_true ).

  ENDMETHOD.

ENDCLASS.
