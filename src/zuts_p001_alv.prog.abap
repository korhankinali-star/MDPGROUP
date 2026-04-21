*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_ALV
*&---------------------------------------------------------------------*
*& Servis tipine gore farkli kolonlarla dinamik ALV gosterimi:
*&   - display_urun     -> Urun detay listesi
*&   - display_bildirim -> Donen mesaj listesi (TIP/KOD/METIN)
*&   - display_stok     -> Stok kayitlari
*& ALV basligi her durumda HTTP/sure/sonuc ozetini icerir.
*&---------------------------------------------------------------------*

CLASS lcl_alv_view DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS display_urun
      IMPORTING !is_summary TYPE lcl_service_runner=>ty_run_result
      CHANGING  !ct_rows    TYPE lcl_service_runner=>tt_urun_rows.

    METHODS display_bildirim
      IMPORTING !is_summary TYPE lcl_service_runner=>ty_run_result
      CHANGING  !ct_rows    TYPE lcl_service_runner=>tt_bildirim_rows.

    METHODS display_stok
      IMPORTING !is_summary TYPE lcl_service_runner=>ty_run_result
      CHANGING  !ct_rows    TYPE lcl_service_runner=>tt_stok_rows.

  PRIVATE SECTION.
    METHODS build_title
      IMPORTING
        !is_summary      TYPE lcl_service_runner=>ty_run_result
      RETURNING
        VALUE(rv_title)  TYPE string.

    METHODS apply_common_settings
      IMPORTING
        !io_alv     TYPE REF TO cl_salv_table
        !is_summary TYPE lcl_service_runner=>ty_run_result.

    METHODS set_col
      IMPORTING
        !io_cols  TYPE REF TO cl_salv_columns_table
        !iv_name  TYPE lvc_fname
        !iv_short TYPE scrtext_s
        !iv_med   TYPE scrtext_m
        !iv_long  TYPE scrtext_l.

    METHODS hide_col
      IMPORTING
        !io_cols TYPE REF TO cl_salv_columns_table
        !iv_name TYPE lvc_fname.

    METHODS handle_salv_exc
      IMPORTING
        !ix_exc TYPE REF TO cx_root.

ENDCLASS.


CLASS lcl_alv_view IMPLEMENTATION.

  METHOD build_title.

    DATA(lv_status) = COND string(
      WHEN is_summary-http_status = 0
       THEN 'BAGLANTI YOK'
       ELSE |HTTP { is_summary-http_status }| ).

    rv_title = |{ is_summary-service_name } |
            && |[{ lv_status }, { is_summary-duration_ms } ms]|.

    IF is_summary-sonuc_kodu IS NOT INITIAL.
      rv_title = |{ rv_title } - Sonuc: { is_summary-sonuc_kodu }|.
    ENDIF.

    IF is_summary-sonuc_mesaji IS NOT INITIAL.
      rv_title = |{ rv_title } - { is_summary-sonuc_mesaji }|.
    ENDIF.

    IF is_summary-snc_id IS NOT INITIAL.
      rv_title = |{ rv_title } - SNC: { is_summary-snc_id }|.
    ENDIF.

  ENDMETHOD.


  METHOD apply_common_settings.
    DATA lo_func     TYPE REF TO cl_salv_functions_list.
    DATA lo_settings TYPE REF TO cl_salv_display_settings.

    lo_func = io_alv->get_functions( ).
    IF lo_func IS BOUND.
      lo_func->set_all( abap_true ).
    ENDIF.

    lo_settings = io_alv->get_display_settings( ).
    IF lo_settings IS BOUND.
      lo_settings->set_striped_pattern( abap_true ).
      lo_settings->set_list_header( CONV lvc_title( build_title( is_summary ) ) ).
    ENDIF.

    " Hata varsa kullaniciya da bir popup mesaj gosterelim
    IF is_summary-error_msg IS NOT INITIAL AND is_summary-success_flag = abap_false.
      DATA(lv_txt) = CONV bapi_msg( is_summary-error_msg ).
      MESSAGE lv_txt TYPE 'I' DISPLAY LIKE 'E'.
    ENDIF.
  ENDMETHOD.


  METHOD set_col.
    DATA lo_col TYPE REF TO cl_salv_column_table.
    TRY.
        lo_col ?= io_cols->get_column( iv_name ).
        IF lo_col IS BOUND.
          lo_col->set_short_text(  iv_short ).
          lo_col->set_medium_text( iv_med ).
          lo_col->set_long_text(   iv_long ).
        ENDIF.
      CATCH cx_salv_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD hide_col.
    DATA lo_col TYPE REF TO cl_salv_column_table.
    TRY.
        lo_col ?= io_cols->get_column( iv_name ).
        IF lo_col IS BOUND.
          lo_col->set_visible( abap_false ).
        ENDIF.
      CATCH cx_salv_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD handle_salv_exc.
    MESSAGE ix_exc->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
  ENDMETHOD.


*======================================================================*
*  URUN - Urun Sorgulama / Urun Kayit sonuclari
*======================================================================*
  METHOD display_urun.

    DATA lo_alv  TYPE REF TO cl_salv_table.
    DATA lo_cols TYPE REF TO cl_salv_columns_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = ct_rows ).

        IF lo_alv IS NOT BOUND.
          RETURN.
        ENDIF.

        apply_common_settings( io_alv = lo_alv is_summary = is_summary ).

        lo_cols = lo_alv->get_columns( ).
        IF lo_cols IS BOUND.
          lo_cols->set_optimize( abap_true ).

          set_col( io_cols = lo_cols iv_name = 'URUN_NO'
                   iv_short = 'Urun No' iv_med = 'Urun Numarasi' iv_long = 'Birincil Urun Numarasi' ).
          set_col( io_cols = lo_cols iv_name = 'URUN_ADI'
                   iv_short = 'Urun Adi' iv_med = 'Urun Adi' iv_long = 'Etiket Adi' ).
          set_col( io_cols = lo_cols iv_name = 'MARKA'
                   iv_short = 'Marka' iv_med = 'Marka' iv_long = 'Marka Adi' ).
          set_col( io_cols = lo_cols iv_name = 'MODEL'
                   iv_short = 'Model' iv_med = 'Model' iv_long = 'Versiyon / Model' ).
          set_col( io_cols = lo_cols iv_name = 'URUN_TIPI'
                   iv_short = 'Tip' iv_med = 'Urun Tipi' iv_long = 'Urun Tipi' ).
          set_col( io_cols = lo_cols iv_name = 'SINIF'
                   iv_short = 'Sinif' iv_med = 'Sinif' iv_long = 'Tibbi Cihaz Sinifi' ).
          set_col( io_cols = lo_cols iv_name = 'YONETMELIK'
                   iv_short = 'Yon.' iv_med = 'Yonetmelik' iv_long = 'Yonetmelik' ).
          set_col( io_cols = lo_cols iv_name = 'ITHAL_IMAL'
                   iv_short = 'Ith/Imal' iv_med = 'Ithal / Imal' iv_long = 'Ithal Imal Bilgisi' ).
          set_col( io_cols = lo_cols iv_name = 'KAYIT_DURUMU'
                   iv_short = 'Durum' iv_med = 'Kayit Durumu' iv_long = 'Kayit Durumu' ).
          set_col( io_cols = lo_cols iv_name = 'URETICI_FIRMA'
                   iv_short = 'Uretici' iv_med = 'Uretici Firma' iv_long = 'Uretici Firma' ).
          set_col( io_cols = lo_cols iv_name = 'MENSEI'
                   iv_short = 'Mensei' iv_med = 'Mensei Ulke' iv_long = 'Mensei Ulke(ler)' ).
        ENDIF.

        lo_alv->display( ).

      CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx).
        handle_salv_exc( lx ).
    ENDTRY.

  ENDMETHOD.


*======================================================================*
*  BILDIRIM - Ithalat / Verme / Alma mesajlari
*======================================================================*
  METHOD display_bildirim.

    DATA lo_alv  TYPE REF TO cl_salv_table.
    DATA lo_cols TYPE REF TO cl_salv_columns_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = ct_rows ).

        IF lo_alv IS NOT BOUND.
          RETURN.
        ENDIF.

        apply_common_settings( io_alv = lo_alv is_summary = is_summary ).

        lo_cols = lo_alv->get_columns( ).
        IF lo_cols IS BOUND.
          lo_cols->set_optimize( abap_true ).

          set_col( io_cols = lo_cols iv_name = 'MESAJ_IKON'
                   iv_short = 'Durum' iv_med = 'Durum' iv_long = 'Mesaj Tipi Durum' ).
          set_col( io_cols = lo_cols iv_name = 'MESAJ_TIPI'
                   iv_short = 'Tip' iv_med = 'Mesaj Tipi' iv_long = 'Mesaj Tipi (BILGI/UYARI/HATA)' ).
          set_col( io_cols = lo_cols iv_name = 'MESAJ_KODU'
                   iv_short = 'Kod' iv_med = 'Mesaj Kodu' iv_long = 'Mesaj Kodu' ).
          set_col( io_cols = lo_cols iv_name = 'MESAJ_METNI'
                   iv_short = 'Mesaj' iv_med = 'Mesaj Metni' iv_long = 'Mesaj Metni' ).
          set_col( io_cols = lo_cols iv_name = 'PARAMETRE'
                   iv_short = 'Param' iv_med = 'Parametreler' iv_long = 'Mesaj Parametreleri' ).
          set_col( io_cols = lo_cols iv_name = 'SNC_ID'
                   iv_short = 'SNC' iv_med = 'Bildirim ID' iv_long = 'Bildirim ID (SNC)' ).
        ENDIF.

        lo_alv->display( ).

      CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx).
        handle_salv_exc( lx ).
    ENDTRY.

  ENDMETHOD.


*======================================================================*
*  STOK - Stok Sorgulama kayitlari
*======================================================================*
  METHOD display_stok.

    DATA lo_alv  TYPE REF TO cl_salv_table.
    DATA lo_cols TYPE REF TO cl_salv_columns_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = ct_rows ).

        IF lo_alv IS NOT BOUND.
          RETURN.
        ENDIF.

        apply_common_settings( io_alv = lo_alv is_summary = is_summary ).

        lo_cols = lo_alv->get_columns( ).
        IF lo_cols IS BOUND.
          lo_cols->set_optimize( abap_true ).

          set_col( io_cols = lo_cols iv_name = 'URUN_NO'
                   iv_short = 'Urun No' iv_med = 'Urun Numarasi' iv_long = 'Urun / Barkod Numarasi' ).
          set_col( io_cols = lo_cols iv_name = 'LOT_NO'
                   iv_short = 'Lot' iv_med = 'Lot Numarasi' iv_long = 'Lot / Batch Numarasi' ).
          set_col( io_cols = lo_cols iv_name = 'SERI_NO'
                   iv_short = 'Seri' iv_med = 'Seri Numarasi' iv_long = 'Seri / Sira Numarasi' ).
          set_col( io_cols = lo_cols iv_name = 'ADET'
                   iv_short = 'Adet' iv_med = 'Adet' iv_long = 'Adet' ).
          set_col( io_cols = lo_cols iv_name = 'MARKA'
                   iv_short = 'Marka' iv_med = 'Marka' iv_long = 'Marka' ).
          set_col( io_cols = lo_cols iv_name = 'URETICI_NO'
                   iv_short = 'Uret. No' iv_med = 'Uretici No' iv_long = 'Uretici Firma No (UIK)' ).
          set_col( io_cols = lo_cols iv_name = 'URETICI_UNVAN'
                   iv_short = 'Uret. Unvan' iv_med = 'Uretici Unvan' iv_long = 'Uretici Firma Unvani' ).
          set_col( io_cols = lo_cols iv_name = 'URETIM_TARIHI'
                   iv_short = 'URT' iv_med = 'Uretim Tarihi' iv_long = 'Uretim Tarihi' ).
          set_col( io_cols = lo_cols iv_name = 'SON_KULLANMA'
                   iv_short = 'SKT' iv_med = 'Son Kullanma' iv_long = 'Son Kullanma Tarihi' ).
        ENDIF.

        lo_alv->display( ).

      CATCH cx_salv_msg cx_salv_not_found INTO DATA(lx).
        handle_salv_exc( lx ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
