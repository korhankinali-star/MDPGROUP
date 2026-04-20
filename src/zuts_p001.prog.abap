*&---------------------------------------------------------------------*
*& Report  ZUTS_P001
*&---------------------------------------------------------------------*
*& UTS Web Servis Test Programi
*& - ZUTS_CL001 sinifini tuketir
*& - PDF dokumanindan alinan ornek (dummy) verilerle servisleri test eder
*& - Sadece TEST ortami desteklidir
*&
*& Mimari: Clean-core + OOP
*&  LCL_DUMMY_DATA     : PDF'ten alinan ornek JSON verilerini saglar
*&  LCL_SERVICE_RUNNER : ZUTS_CL001'i kullanarak secilen servisi calistirir
*&  LCL_ALV_VIEW       : Sonucu SALV ile goruntuler
*&  LCL_APP            : Uygulama orkestratoru (controller)
*&---------------------------------------------------------------------*
REPORT zuts_p001.

*&---------------------------------------------------------------------*
*& SECIM EKRANI
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

  PARAMETERS:
    p_srv1 RADIOBUTTON GROUP g1 DEFAULT 'X',  "! Urun Sorgulama
    p_srv2 RADIOBUTTON GROUP g1,              "! Urun Kayit / Guncelleme
    p_srv3 RADIOBUTTON GROUP g1,              "! Ithalat Bildirimi
    p_srv4 RADIOBUTTON GROUP g1,              "! Verme (Satis) Bildirimi
    p_srv5 RADIOBUTTON GROUP g1,              "! Alma (Kabul) Bildirimi
    p_srv6 RADIOBUTTON GROUP g1.              "! Stok Sorgulama

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.

  PARAMETERS:
    p_env   TYPE string LENGTH 4 DEFAULT 'TEST' MODIF ID env,
    p_dest  TYPE rfcdest,
    p_token TYPE string LOWER CASE,
    p_dummy AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b2.

*&---------------------------------------------------------------------*
*& LCL_DUMMY_DATA - PDF'ten alinan ornek JSON'lar
*&---------------------------------------------------------------------*
CLASS lcl_dummy_data DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS get_urun_sorgulama_json RETURNING VALUE(rv_json) TYPE string.
    CLASS-METHODS get_urun_kayit_json     RETURNING VALUE(rv_json) TYPE string.
    CLASS-METHODS get_ithalat_json        RETURNING VALUE(rv_json) TYPE string.
    CLASS-METHODS get_verme_json          RETURNING VALUE(rv_json) TYPE string.
    CLASS-METHODS get_alma_json           RETURNING VALUE(rv_json) TYPE string.
    CLASS-METHODS get_stok_sorgulama_json RETURNING VALUE(rv_json) TYPE string.
ENDCLASS.

CLASS lcl_dummy_data IMPLEMENTATION.

  METHOD get_urun_sorgulama_json.
    " Ref: PDF 3.7.3 Urun Sorgulama Servisi Ornek Istek
    rv_json = `{ "UNO" : "048327885764" }`.
  ENDMETHOD.

  METHOD get_urun_kayit_json.
    " PDF'te dogrudan ornek istek bulunmadigindan,
    " cevap yapisi baz alinarak ornek kayit JSON'u olusturulmustur.
    rv_json =
      `{`                                                                            &&
      `  "UNO": "1111111110317",`                                                    &&
      `  "urunAdi": "Ornek Tibbi Cihaz",`                                            &&
      `  "markaAdi": "Ornek Marka",`                                                 &&
      `  "versiyonModel": "XXX-Q1",`                                                 &&
      `  "urunTipi": "TIBBI_CIHAZ",`                                                 &&
      `  "ithalImalBilgisi": "IMAL",`                                                &&
      `  "sinif": "SINIF_III",`                                                      &&
      `  "yonetmelik": "93/42/EEC",`                                                 &&
      `  "tekKullanimlik": "HAYIR",`                                                 &&
      `  "sterilPaketlendi": "HAYIR",`                                               &&
      `  "ek3KapsamindaMi": "HAYIR",`                                                &&
      `  "bransKodu": "81",`                                                         &&
      `  "gmdnKodu": "30857",`                                                       &&
      `  "rafOmruVar": "HAYIR"`                                                      &&
      `}`.
  ENDMETHOD.

  METHOD get_ithalat_json.
    " Ref: PDF 3.1.2.3 Ithalat Bildirimi Ornek Istek (lot takip edilen urun)
    rv_json =
      `{`                                                                            &&
      `  "UNO": "1111111110058",`                                                    &&
      `  "LNO": "250515186001",`                                                     &&
      `  "ADT": 100,`                                                                &&
      `  "UDI": "011111111110058111603021719030210250515186001",`                    &&
      `  "URT": "2016-03-02",`                                                       &&
      `  "SKT": "2019-03-02",`                                                       &&
      `  "IEU": "038",`                                                              &&
      `  "MEU": "452",`                                                              &&
      `  "GBN": "15343100IM003176"`                                                  &&
      `}`.
  ENDMETHOD.

  METHOD get_verme_json.
    " Ref: PDF 3.1.4.3 Verme Bildirimi Ornek Istek
    rv_json =
      `{`                                                                            &&
      `  "UNO": "2451643000007",`                                                    &&
      `  "LNO": "250515186001",`                                                     &&
      `  "ADT": 25,`                                                                 &&
      `  "KUN": 7,`                                                                  &&
      `  "BEN": "HAYIR",`                                                            &&
      `  "BNO": "123B",`                                                             &&
      `  "GIT": "2018-10-31"`                                                        &&
      `}`.
  ENDMETHOD.

  METHOD get_alma_json.
    " Ref: PDF 3.1.6.3 Alma Bildirimi Ornek Istek 2
    rv_json =
      `{`                                                                            &&
      `  "UNO": "1111111110324",`                                                    &&
      `  "LNO": "250515186001",`                                                     &&
      `  "ADT": 5,`                                                                  &&
      `  "GKK": 10`                                                                  &&
      `}`.
  ENDMETHOD.

  METHOD get_stok_sorgulama_json.
    " Ref: PDF 3.4.18.4 Stok Yapilabilir Tekil Urun Sorgula Ornek Istek
    rv_json = `{ "UNO" : "792461048126" }`.
  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& LCL_SERVICE_RUNNER - Servis calistirici
*&---------------------------------------------------------------------*
CLASS lcl_service_runner DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_run_result,
        service_code   TYPE string,
        service_name   TYPE string,
        endpoint       TYPE string,
        http_status    TYPE i,
        success_flag   TYPE abap_bool,
        success_icon   TYPE icon_d,
        request_json   TYPE string,
        response_json  TYPE string,
        error_msg      TYPE string,
        duration_ms    TYPE i,
      END OF ty_run_result .

    METHODS constructor
      IMPORTING
        !iv_env   TYPE string
        !iv_dest  TYPE rfcdest
        !iv_token TYPE string.

    METHODS run
      IMPORTING
        !iv_service_code TYPE string
        !iv_use_dummy    TYPE abap_bool
      RETURNING
        VALUE(rs_result) TYPE ty_run_result.

  PRIVATE SECTION.
    DATA mo_client TYPE REF TO zuts_cl001.
    DATA mv_token  TYPE string.

    METHODS build_dummy_req
      IMPORTING
        !iv_service_code TYPE string
      RETURNING
        VALUE(rv_json)   TYPE string.
ENDCLASS.

CLASS lcl_service_runner IMPLEMENTATION.

  METHOD constructor.
    DATA(lv_use_dest) = xsdbool( iv_dest IS NOT INITIAL ).
    CREATE OBJECT mo_client
      EXPORTING
        iv_dest              = iv_dest
        iv_env               = iv_env
        iv_destination_mode  = lv_use_dest.
    mv_token = iv_token.
  ENDMETHOD.


  METHOD build_dummy_req.
    rv_json = SWITCH string( iv_service_code
                WHEN 'URUN_SORGULAMA'      THEN lcl_dummy_data=>get_urun_sorgulama_json( )
                WHEN 'URUN_KAYIT_GUNCELLE' THEN lcl_dummy_data=>get_urun_kayit_json( )
                WHEN 'ITHALAT_BILDIRIMI'   THEN lcl_dummy_data=>get_ithalat_json( )
                WHEN 'VERME_BILDIRIMI'     THEN lcl_dummy_data=>get_verme_json( )
                WHEN 'ALMA_BILDIRIMI'      THEN lcl_dummy_data=>get_alma_json( )
                WHEN 'STOK_SORGULAMA'      THEN lcl_dummy_data=>get_stok_sorgulama_json( ) ).
  ENDMETHOD.


  METHOD run.

    DATA ls_resp TYPE zuts_cl001=>ty_response.

    GET RUN TIME FIELD DATA(lv_start).

    rs_result-service_code = iv_service_code.

    " Servis adi ve endpoint bilgisi
    CASE iv_service_code.
      WHEN 'URUN_SORGULAMA'.
        rs_result-service_name = 'Urun Sorgulama'.
        rs_result-endpoint     = zuts_cl001=>c_uri-urun_sorgulama.
      WHEN 'URUN_KAYIT_GUNCELLE'.
        rs_result-service_name = 'Urun Kayit / Guncelleme'.
        rs_result-endpoint     = zuts_cl001=>c_uri-urun_kayit.
      WHEN 'ITHALAT_BILDIRIMI'.
        rs_result-service_name = 'Ithalat Bildirimi'.
        rs_result-endpoint     = zuts_cl001=>c_uri-ithalat_bildirimi.
      WHEN 'VERME_BILDIRIMI'.
        rs_result-service_name = 'Verme (Satis) Bildirimi'.
        rs_result-endpoint     = zuts_cl001=>c_uri-verme_bildirimi.
      WHEN 'ALMA_BILDIRIMI'.
        rs_result-service_name = 'Alma (Kabul) Bildirimi'.
        rs_result-endpoint     = zuts_cl001=>c_uri-alma_bildirimi.
      WHEN 'STOK_SORGULAMA'.
        rs_result-service_name = 'Stok Sorgulama'.
        rs_result-endpoint     = zuts_cl001=>c_uri-stok_sorgulama.
    ENDCASE.

    " Dummy istek JSON'u hazirla
    IF iv_use_dummy = abap_true.
      rs_result-request_json = build_dummy_req( iv_service_code ).
    ENDIF.

    " Servisi cagir
    CASE iv_service_code.
      WHEN 'URUN_SORGULAMA'.
        mo_client->urun_sorgulama(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = rs_result-request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'URUN_KAYIT_GUNCELLE'.
        mo_client->urun_kayit_guncelle(
          EXPORTING iv_token     = mv_token
                    iv_operation = 'KAYIT'
                    iv_raw_json  = rs_result-request_json
          IMPORTING es_result    = ls_resp ).

      WHEN 'ITHALAT_BILDIRIMI'.
        mo_client->ithalat_bildirimi(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = rs_result-request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'VERME_BILDIRIMI'.
        mo_client->verme_bildirimi(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = rs_result-request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'ALMA_BILDIRIMI'.
        mo_client->alma_bildirimi(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = rs_result-request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'STOK_SORGULAMA'.
        mo_client->stok_sorgulama(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = rs_result-request_json
          IMPORTING es_result   = ls_resp ).
    ENDCASE.

    GET RUN TIME FIELD DATA(lv_end).
    rs_result-duration_ms = ( lv_end - lv_start ) / 1000.

    rs_result-http_status   = ls_resp-http_status.
    rs_result-success_flag  = ls_resp-success_flag.
    rs_result-response_json = ls_resp-response.
    rs_result-error_msg     = ls_resp-error_msg.
    rs_result-success_icon  = COND #( WHEN ls_resp-success_flag = abap_true
                                        THEN icon_led_green
                                        ELSE icon_led_red ).

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& LCL_ALV_VIEW - Sonuc goruntuleme
*&---------------------------------------------------------------------*
CLASS lcl_alv_view DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS display
      IMPORTING
        !it_results TYPE STANDARD TABLE.
ENDCLASS.

CLASS lcl_alv_view IMPLEMENTATION.

  METHOD display.

    DATA lo_alv      TYPE REF TO cl_salv_table.
    DATA lo_cols     TYPE REF TO cl_salv_columns_table.
    DATA lo_col      TYPE REF TO cl_salv_column_table.
    DATA lo_settings TYPE REF TO cl_salv_display_settings.
    DATA lo_func     TYPE REF TO cl_salv_functions_list.

    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN it_results TO <lt_data>.

    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_alv
          CHANGING  t_table      = <lt_data> ).

        lo_func = lo_alv->get_functions( ).
        lo_func->set_all( abap_true ).

        lo_settings = lo_alv->get_display_settings( ).
        lo_settings->set_striped_pattern( abap_true ).
        lo_settings->set_list_header( 'UTS Servis Test Sonucu' ).

        lo_cols = lo_alv->get_columns( ).
        lo_cols->set_optimize( abap_true ).

        TRY.
            lo_col ?= lo_cols->get_column( 'SUCCESS_ICON' ).
            lo_col->set_short_text( 'Durum' ).
            lo_col->set_medium_text( 'Durum' ).
            lo_col->set_long_text( 'Durum' ).

            lo_col ?= lo_cols->get_column( 'SERVICE_NAME' ).
            lo_col->set_short_text( 'Servis' ).
            lo_col->set_medium_text( 'Servis' ).
            lo_col->set_long_text( 'Servis Adi' ).

            lo_col ?= lo_cols->get_column( 'SERVICE_CODE' ).
            lo_col->set_visible( abap_false ).

            lo_col ?= lo_cols->get_column( 'ENDPOINT' ).
            lo_col->set_short_text( 'Endpoint' ).
            lo_col->set_medium_text( 'Endpoint' ).
            lo_col->set_long_text( 'Endpoint URI' ).

            lo_col ?= lo_cols->get_column( 'HTTP_STATUS' ).
            lo_col->set_short_text( 'HTTP' ).
            lo_col->set_medium_text( 'HTTP Kodu' ).
            lo_col->set_long_text( 'HTTP Durum Kodu' ).

            lo_col ?= lo_cols->get_column( 'SUCCESS_FLAG' ).
            lo_col->set_visible( abap_false ).

            lo_col ?= lo_cols->get_column( 'DURATION_MS' ).
            lo_col->set_short_text( 'Sure ms' ).
            lo_col->set_medium_text( 'Sure (ms)' ).
            lo_col->set_long_text( 'Cagri Suresi (ms)' ).

            lo_col ?= lo_cols->get_column( 'REQUEST_JSON' ).
            lo_col->set_short_text( 'Istek' ).
            lo_col->set_medium_text( 'Istek JSON' ).
            lo_col->set_long_text( 'Istek JSON' ).

            lo_col ?= lo_cols->get_column( 'RESPONSE_JSON' ).
            lo_col->set_short_text( 'Cevap' ).
            lo_col->set_medium_text( 'Cevap JSON' ).
            lo_col->set_long_text( 'Cevap JSON' ).

            lo_col ?= lo_cols->get_column( 'ERROR_MSG' ).
            lo_col->set_short_text( 'Hata' ).
            lo_col->set_medium_text( 'Hata Mesaji' ).
            lo_col->set_long_text( 'Hata Mesaji' ).
          CATCH cx_salv_not_found.
        ENDTRY.

        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_salv).
        MESSAGE lx_salv->get_text( ) TYPE 'E'.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& LCL_APP - Orkestratör
*&---------------------------------------------------------------------*
CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS run.
  PRIVATE SECTION.
    METHODS get_selected_service
      RETURNING VALUE(rv_code) TYPE string.
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

  METHOD run.

    " Token bos kontrolu
    IF p_token IS INITIAL.
      MESSAGE 'JWT Token girilmelidir' TYPE 'E'.
      RETURN.
    ENDIF.

    DATA(lo_runner) = NEW lcl_service_runner(
                            iv_env   = 'TEST'
                            iv_dest  = p_dest
                            iv_token = p_token ).

    DATA(ls_result) = lo_runner->run(
                        iv_service_code = get_selected_service( )
                        iv_use_dummy    = p_dummy ).

    DATA lt_results TYPE STANDARD TABLE OF lcl_service_runner=>ty_run_result.
    APPEND ls_result TO lt_results.

    DATA(lo_view) = NEW lcl_alv_view( ).
    lo_view->display( lt_results ).

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN OUTPUT - Ortam alanini salt-okunur yap
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'ENV'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*&---------------------------------------------------------------------*
*& START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  NEW lcl_app( )->run( ).
