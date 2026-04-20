*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_SRV
*&---------------------------------------------------------------------*
*& Servis runner + PDF'ten alinan dummy veri saglayicisi
*&   - LCL_DUMMY_DATA     : PDF'teki ornek JSON payload'larini saglar
*&   - LCL_SERVICE_RUNNER : ZUTS_CL001 araciligiyla secilen servisi cagirir
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& LCL_DUMMY_DATA
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
    " Cevap yapisi baz alinarak olusturulmus ornek kayit JSON'u
    rv_json =
      `{`                                        &&
      `  "UNO": "1111111110317",`                &&
      `  "urunAdi": "Ornek Tibbi Cihaz",`        &&
      `  "markaAdi": "Ornek Marka",`             &&
      `  "versiyonModel": "XXX-Q1",`             &&
      `  "urunTipi": "TIBBI_CIHAZ",`             &&
      `  "ithalImalBilgisi": "IMAL",`            &&
      `  "sinif": "SINIF_III",`                  &&
      `  "yonetmelik": "93/42/EEC",`             &&
      `  "tekKullanimlik": "HAYIR",`             &&
      `  "sterilPaketlendi": "HAYIR",`           &&
      `  "ek3KapsamindaMi": "HAYIR",`            &&
      `  "bransKodu": "81",`                     &&
      `  "gmdnKodu": "30857",`                   &&
      `  "rafOmruVar": "HAYIR"`                  &&
      `}`.
  ENDMETHOD.

  METHOD get_ithalat_json.
    " Ref: PDF 3.1.2.3 Ithalat Bildirimi Ornek Istek (lot takip edilen urun)
    rv_json =
      `{`                                                                 &&
      `  "UNO": "1111111110058",`                                         &&
      `  "LNO": "250515186001",`                                          &&
      `  "ADT": 100,`                                                     &&
      `  "UDI": "011111111110058111603021719030210250515186001",`         &&
      `  "URT": "2016-03-02",`                                            &&
      `  "SKT": "2019-03-02",`                                            &&
      `  "IEU": "038",`                                                   &&
      `  "MEU": "452",`                                                   &&
      `  "GBN": "15343100IM003176"`                                       &&
      `}`.
  ENDMETHOD.

  METHOD get_verme_json.
    " Ref: PDF 3.1.4.3 Verme Bildirimi Ornek Istek
    rv_json =
      `{`                                  &&
      `  "UNO": "2451643000007",`          &&
      `  "LNO": "250515186001",`           &&
      `  "ADT": 25,`                       &&
      `  "KUN": 7,`                        &&
      `  "BEN": "HAYIR",`                  &&
      `  "BNO": "123B",`                   &&
      `  "GIT": "2018-10-31"`              &&
      `}`.
  ENDMETHOD.

  METHOD get_alma_json.
    " Ref: PDF 3.1.6.3 Alma Bildirimi Ornek Istek 2
    rv_json =
      `{`                            &&
      `  "UNO": "1111111110324",`    &&
      `  "LNO": "250515186001",`     &&
      `  "ADT": 5,`                  &&
      `  "GKK": 10`                  &&
      `}`.
  ENDMETHOD.

  METHOD get_stok_sorgulama_json.
    " Ref: PDF 3.4.18.4 Stok Yapilabilir Tekil Urun Sorgula Ornek Istek
    rv_json = `{ "UNO" : "792461048126" }`.
  ENDMETHOD.

ENDCLASS.


*&---------------------------------------------------------------------*
*& LCL_SERVICE_RUNNER
*&---------------------------------------------------------------------*
CLASS lcl_service_runner DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_run_result,
        service_code  TYPE string,
        service_name  TYPE string,
        endpoint      TYPE string,
        http_status   TYPE i,
        success_flag  TYPE abap_bool,
        success_icon  TYPE icon_d,
        request_json  TYPE string,
        response_json TYPE string,
        error_msg     TYPE string,
        duration_ms   TYPE i,
      END OF ty_run_result .

    TYPES:
      tt_run_results TYPE STANDARD TABLE OF ty_run_result WITH DEFAULT KEY .

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
        iv_dest             = iv_dest
        iv_env              = iv_env
        iv_destination_mode = lv_use_dest.

    IF mo_client IS NOT BOUND.
      MESSAGE 'ZUTS_CL001 istemcisi olusturulamadi' TYPE 'E'.
    ENDIF.

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
      WHEN OTHERS.
        rs_result-service_name = 'Gecersiz Servis'.
        rs_result-error_msg    = |Bilinmeyen servis kodu: { iv_service_code }|.
        rs_result-success_icon = icon_led_red.
        RETURN.
    ENDCASE.

    IF iv_use_dummy = abap_true.
      rs_result-request_json = build_dummy_req( iv_service_code ).
    ENDIF.

    IF mo_client IS NOT BOUND.
      rs_result-error_msg    = 'HTTP istemcisi hazir degil'.
      rs_result-success_icon = icon_led_red.
      RETURN.
    ENDIF.

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
