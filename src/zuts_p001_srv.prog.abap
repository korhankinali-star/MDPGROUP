*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_SRV
*&---------------------------------------------------------------------*
*& Servis runner + PDF'ten alinan dummy veri saglayicisi
*&   - LCL_DUMMY_DATA     : PDF'teki ornek JSON payload'larini saglar
*&   - LCL_SERVICE_RUNNER : ZUTS_CL001 araciligiyla secilen servisi cagirir
*&                         ve cevap JSON'unu parse edip ALV icin uygun
*&                         alanlari doldurur.
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
    rv_json = `{ "UNO" : "048327885764" }`.
  ENDMETHOD.

  METHOD get_urun_kayit_json.
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
    rv_json =
      `{`                            &&
      `  "UNO": "1111111110324",`    &&
      `  "LNO": "250515186001",`     &&
      `  "ADT": 5,`                  &&
      `  "GKK": 10`                  &&
      `}`.
  ENDMETHOD.

  METHOD get_stok_sorgulama_json.
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
        duration_ms   TYPE i,
        " Parse edilmis response alanlari (ALV'de gosterilir)
        sonuc_kodu    TYPE string,
        sonuc_mesaji  TYPE string,
        snc_id        TYPE string,
        mesaj_tipi    TYPE string,
        detay_sayisi  TYPE i,
        " Ham response ve hata (gizli/opsiyonel)
        response_json TYPE string,
        error_msg     TYPE string,
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

*---------------------------------------------------------------------*
*  RESPONSE PARSE TIPLERI
*---------------------------------------------------------------------*

    "! Urun Sorgulama / Urun Kayit cevap yapisi (camelCase)
    TYPES:
      BEGIN OF ty_urun_detay,
        birincilurunnumarasi TYPE string,
        markaadi             TYPE string,
        uruntipi             TYPE string,
        kayitdurumu          TYPE string,
        ureticifirma         TYPE string,
      END OF ty_urun_detay .
    TYPES:
      BEGIN OF ty_resp_urun,
        sonuc         TYPE i,
        sonucmesaji   TYPE string,
        urundetaylist TYPE STANDARD TABLE OF ty_urun_detay WITH DEFAULT KEY,
      END OF ty_resp_urun .

    "! Bildirim servisleri cevap yapisi (upper-case)
    TYPES:
      BEGIN OF ty_msj_item,
        met TYPE string,
        kod TYPE string,
        tip TYPE string,
      END OF ty_msj_item .
    TYPES:
      BEGIN OF ty_resp_bildirim,
        snc TYPE string,
        msj TYPE STANDARD TABLE OF ty_msj_item WITH DEFAULT KEY,
      END OF ty_resp_bildirim .

    "! Stok Sorgulama cevap yapisi
    TYPES:
      BEGIN OF ty_stok_item,
        uno TYPE string,
        lno TYPE string,
        sno TYPE string,
        urt TYPE string,
        skt TYPE string,
      END OF ty_stok_item .
    TYPES:
      BEGIN OF ty_stok_snc,
        lst TYPE STANDARD TABLE OF ty_stok_item WITH DEFAULT KEY,
        off TYPE string,
      END OF ty_stok_snc .
    TYPES:
      BEGIN OF ty_resp_stok,
        snc TYPE ty_stok_snc,
      END OF ty_resp_stok .

    METHODS build_dummy_req
      IMPORTING
        !iv_service_code TYPE string
      RETURNING
        VALUE(rv_json)   TYPE string.

    METHODS parse_response
      IMPORTING
        !iv_service_code TYPE string
        !iv_response     TYPE string
      CHANGING
        !cs_result       TYPE ty_run_result.

    METHODS parse_urun_response
      IMPORTING
        !iv_response TYPE string
      CHANGING
        !cs_result   TYPE ty_run_result.

    METHODS parse_bildirim_response
      IMPORTING
        !iv_response TYPE string
      CHANGING
        !cs_result   TYPE ty_run_result.

    METHODS parse_stok_response
      IMPORTING
        !iv_response TYPE string
      CHANGING
        !cs_result   TYPE ty_run_result.

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


*======================================================================*
*  RESPONSE PARSE - DISPATCHER
*======================================================================*
  METHOD parse_response.

    IF iv_response IS INITIAL.
      RETURN.
    ENDIF.

    CASE iv_service_code.
      WHEN 'URUN_SORGULAMA' OR 'URUN_KAYIT_GUNCELLE'.
        parse_urun_response( EXPORTING iv_response = iv_response
                             CHANGING  cs_result   = cs_result ).

      WHEN 'ITHALAT_BILDIRIMI' OR 'VERME_BILDIRIMI' OR 'ALMA_BILDIRIMI'.
        parse_bildirim_response( EXPORTING iv_response = iv_response
                                 CHANGING  cs_result   = cs_result ).

      WHEN 'STOK_SORGULAMA'.
        parse_stok_response( EXPORTING iv_response = iv_response
                             CHANGING  cs_result   = cs_result ).
    ENDCASE.

  ENDMETHOD.


  METHOD parse_urun_response.

    DATA ls_parsed TYPE ty_resp_urun.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json        = iv_response
                    pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING  data        = ls_parsed ).

        cs_result-sonuc_kodu   = |{ ls_parsed-sonuc }|.
        cs_result-sonuc_mesaji = ls_parsed-sonucmesaji.
        cs_result-detay_sayisi = lines( ls_parsed-urundetaylist ).

        IF cs_result-detay_sayisi > 0 AND cs_result-sonuc_mesaji IS INITIAL.
          cs_result-sonuc_mesaji = |Urun bulundu ({ cs_result-detay_sayisi } adet)|.
        ENDIF.

      CATCH cx_root.
        " Parse edilemedi - sorun yok, ham response yine saklaniyor
    ENDTRY.

  ENDMETHOD.


  METHOD parse_bildirim_response.

    DATA ls_parsed TYPE ty_resp_bildirim.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = iv_response
          CHANGING  data = ls_parsed ).

        cs_result-snc_id = ls_parsed-snc.

        IF lines( ls_parsed-msj ) > 0.
          READ TABLE ls_parsed-msj INDEX 1 INTO DATA(ls_msj).
          cs_result-sonuc_kodu   = ls_msj-kod.
          cs_result-sonuc_mesaji = ls_msj-met.
          cs_result-mesaj_tipi   = ls_msj-tip.
          cs_result-detay_sayisi = lines( ls_parsed-msj ).
        ENDIF.

      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.


  METHOD parse_stok_response.

    DATA ls_parsed TYPE ty_resp_stok.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = iv_response
          CHANGING  data = ls_parsed ).

        cs_result-detay_sayisi = lines( ls_parsed-snc-lst ).

        IF cs_result-detay_sayisi > 0.
          cs_result-sonuc_kodu   = 'OK'.
          cs_result-sonuc_mesaji = |Stok kayitlari bulundu ({ cs_result-detay_sayisi } adet)|.
        ELSE.
          cs_result-sonuc_mesaji = 'Stok kaydi bulunamadi'.
        ENDIF.

      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.


*======================================================================*
*  ANA METOD: RUN
*======================================================================*
  METHOD run.

    DATA ls_resp TYPE zuts_cl001=>ty_response.
    DATA lv_request_json TYPE string.

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
      lv_request_json = build_dummy_req( iv_service_code ).
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
                    iv_raw_json = lv_request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'URUN_KAYIT_GUNCELLE'.
        mo_client->urun_kayit_guncelle(
          EXPORTING iv_token     = mv_token
                    iv_operation = 'KAYIT'
                    iv_raw_json  = lv_request_json
          IMPORTING es_result    = ls_resp ).

      WHEN 'ITHALAT_BILDIRIMI'.
        mo_client->ithalat_bildirimi(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = lv_request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'VERME_BILDIRIMI'.
        mo_client->verme_bildirimi(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = lv_request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'ALMA_BILDIRIMI'.
        mo_client->alma_bildirimi(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = lv_request_json
          IMPORTING es_result   = ls_resp ).

      WHEN 'STOK_SORGULAMA'.
        mo_client->stok_sorgulama(
          EXPORTING iv_token    = mv_token
                    iv_raw_json = lv_request_json
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

    " Response'u parse edip ALV alanlarini doldur
    parse_response( EXPORTING iv_service_code = iv_service_code
                              iv_response     = ls_resp-response
                    CHANGING  cs_result       = rs_result ).

  ENDMETHOD.

ENDCLASS.
