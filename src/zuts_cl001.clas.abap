CLASS zuts_cl001 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

************************************************************************
* ZUTS_CL001 - UTS (Ürün Takip Sistemi) Web Servis İstemci Sınıfı
* ---------------------------------------------------------------------
* Kapsanan Servisler:
*   1) URUN_SORGULAMA       - Ürün Sorgulama Servisi
*   2) URUN_KAYIT_GUNCELLE  - Ürün Kayıt / Güncelleme Servisi
*   3) ITHALAT_BILDIRIMI    - İthalat Bildirimi Servisi
*   4) VERME_BILDIRIMI      - Verme (Satış) Bildirimi Servisi
*   5) ALMA_BILDIRIMI       - Alma (Kabul) Bildirimi Servisi
*   6) STOK_SORGULAMA       - Stok Sorgulama Servisi
*
* Her servis çağrısı, kendine özgü log tablosuna istek + yanıt
* bilgileriyle birlikte kaydedilir:
*   - ZUTS_LOG_URNSOR  (Urun Sorgulama)
*   - ZUTS_LOG_URNKYT  (Urun Kayit / Guncelleme)
*   - ZUTS_LOG_ITHBLD  (Ithalat Bildirimi)
*   - ZUTS_LOG_VRMBLD  (Verme Bildirimi)
*   - ZUTS_LOG_ALMBLD  (Alma Bildirimi)
*   - ZUTS_LOG_STKSOR  (Stok Sorgulama)
*
* Ref: UTS-PRJ-TakipVeIzlemeWebServisTanimlariDokumani (Rev. 99)
************************************************************************

  PUBLIC SECTION.

*---------------------------------------------------------------------*
*  ENDPOINT SABİTLERİ (Gerçek / Test Ortamı)
*---------------------------------------------------------------------*
    CONSTANTS:
      BEGIN OF c_env,
        prod TYPE string VALUE 'https://utsuygulama.saglik.gov.tr' ##NO_TEXT,
        test TYPE string VALUE 'https://utstest.saglik.gov.tr' ##NO_TEXT,
      END OF c_env .

    CONSTANTS:
      BEGIN OF c_uri,
        urun_sorgulama      TYPE string VALUE '/UTS/rest/tibbiCihaz/urunSorgula' ##NO_TEXT,
        urun_detay_sorgula  TYPE string VALUE '/UTS/rest/tibbiCihaz/tibbiCihazSorgula' ##NO_TEXT,
        urun_kayit          TYPE string VALUE '/UTS/rest/tibbiCihaz/urunKayit' ##NO_TEXT,
        urun_guncelle       TYPE string VALUE '/UTS/rest/tibbiCihaz/urunGuncelle' ##NO_TEXT,
        ithalat_bildirimi   TYPE string VALUE '/UTS/uh/rest/bildirim/ithalat/ekle' ##NO_TEXT,
        verme_bildirimi     TYPE string VALUE '/UTS/uh/rest/bildirim/verme/ekle' ##NO_TEXT,
        verme_essiz_kimlik  TYPE string VALUE '/UTS/uh/rest/bildirim/verme/ekle/essizKimlik' ##NO_TEXT,
        alma_bildirimi      TYPE string VALUE '/UTS/uh/rest/bildirim/alma/ekle' ##NO_TEXT,
        alma_essiz_kimlik   TYPE string VALUE '/UTS/uh/rest/bildirim/alma/ekle/essizKimlik' ##NO_TEXT,
        stok_sorgulama      TYPE string VALUE '/UTS/uh/rest/stokYapilabilirTekilUrun/sorgula' ##NO_TEXT,
      END OF c_uri .

    CONSTANTS:
      BEGIN OF c_srv,
        urun_sorgulama    TYPE string VALUE 'URUN_SORGULAMA' ##NO_TEXT,
        urun_kayit        TYPE string VALUE 'URUN_KAYIT' ##NO_TEXT,
        urun_guncelle     TYPE string VALUE 'URUN_GUNCELLE' ##NO_TEXT,
        ithalat_bildirimi TYPE string VALUE 'ITHALAT_BILDIRIMI' ##NO_TEXT,
        verme_bildirimi   TYPE string VALUE 'VERME_BILDIRIMI' ##NO_TEXT,
        alma_bildirimi    TYPE string VALUE 'ALMA_BILDIRIMI' ##NO_TEXT,
        stok_sorgulama    TYPE string VALUE 'STOK_SORGULAMA' ##NO_TEXT,
      END OF c_srv .

    CONSTANTS:
      BEGIN OF c_http,
        content_type  TYPE string VALUE 'Content-Type' ##NO_TEXT,
        accept        TYPE string VALUE 'Accept' ##NO_TEXT,
        authorization TYPE string VALUE 'Authorization' ##NO_TEXT,
        appl_json     TYPE string VALUE 'application/json' ##NO_TEXT,
        bearer        TYPE string VALUE 'Bearer ' ##NO_TEXT,
      END OF c_http .

*---------------------------------------------------------------------*
*  YAPILAR - SERVIS REQUEST / RESPONSE
*---------------------------------------------------------------------*
    "! Ortak response yapısı
    TYPES:
      BEGIN OF ty_response,
        http_status  TYPE i,
        response     TYPE string,
        error_msg    TYPE string,
        success_flag TYPE abap_bool,
        duration_ms  TYPE i,
        logid        TYPE sysuuid_c32,
      END OF ty_response .

    "! 1) Ürün Sorgulama Request Alanları
    TYPES:
      BEGIN OF ty_urun_sorgu_req,
        urun_numarasi TYPE string,
        essiz_kimlik  TYPE string,
        lot_numarasi  TYPE string,
        seri_numarasi TYPE string,
      END OF ty_urun_sorgu_req .

    "! 2) Ürün Kayıt/Güncelleme Request Alanları
    TYPES:
      BEGIN OF ty_urun_kayit_req,
        urun_numarasi   TYPE string,
        urun_tipi       TYPE string,
        urun_adi        TYPE string,
        uretici_firma   TYPE string,
        lot_takipli     TYPE abap_bool,
        seri_takipli    TYPE abap_bool,
        sinif           TYPE string,
        ek3_kapsaminda  TYPE string,
        raf_omru        TYPE i,
        raf_omru_birimi TYPE string,
        ham_json        TYPE string,
      END OF ty_urun_kayit_req .

    "! 3) İthalat Bildirimi Request Alanları
    TYPES:
      BEGIN OF ty_ithalat_item,
        uno TYPE string,
        lno TYPE string,
        sno TYPE string,
        urt TYPE string,
        skt TYPE string,
        itt TYPE string,
        adt TYPE i,
        udi TYPE string,
        ieu TYPE n LENGTH 3,
        meu TYPE n LENGTH 3,
        gbn TYPE string,
      END OF ty_ithalat_item .
    TYPES tt_ithalat_items TYPE STANDARD TABLE OF ty_ithalat_item WITH DEFAULT KEY .

    "! 4) Verme (Satış) Bildirimi Request Alanları
    TYPES:
      BEGIN OF ty_verme_item,
        uno        TYPE string,
        lno        TYPE string,
        sno        TYPE string,
        adt        TYPE i,
        udi        TYPE string,
        alan_kurum TYPE string,
        ben        TYPE string,
        gbn        TYPE string,
        itt        TYPE string,
      END OF ty_verme_item .
    TYPES tt_verme_items TYPE STANDARD TABLE OF ty_verme_item WITH DEFAULT KEY .

    "! 5) Alma (Kabul) Bildirimi Request Alanları
    TYPES:
      BEGIN OF ty_alma_item,
        uno         TYPE string,
        lno         TYPE string,
        sno         TYPE string,
        adt         TYPE i,
        udi         TYPE string,
        veren_kurum TYPE string,
        itt         TYPE string,
        gbn         TYPE string,
      END OF ty_alma_item .
    TYPES tt_alma_items TYPE STANDARD TABLE OF ty_alma_item WITH DEFAULT KEY .

    "! 6) Stok Sorgulama Request Alanları
    TYPES:
      BEGIN OF ty_stok_sorgu_req,
        urun_numarasi TYPE string,
        essiz_kimlik  TYPE string,
        lot_numarasi  TYPE string,
        seri_numarasi TYPE string,
        offset        TYPE i,
        limit         TYPE i,
      END OF ty_stok_sorgu_req .

*---------------------------------------------------------------------*
*  CONSTRUCTOR
*---------------------------------------------------------------------*
    METHODS constructor
      IMPORTING
        !iv_dest             TYPE rfcdest   OPTIONAL
        !iv_env              TYPE string    DEFAULT 'TEST'
        !iv_destination_mode TYPE abap_bool DEFAULT abap_false.

*---------------------------------------------------------------------*
*  SERVİS METODLARI
*---------------------------------------------------------------------*
    METHODS urun_sorgulama
      IMPORTING
        !iv_token    TYPE string
        !is_request  TYPE ty_urun_sorgu_req OPTIONAL
        !iv_raw_json TYPE string OPTIONAL
      EXPORTING
        !es_result   TYPE ty_response .

    METHODS urun_kayit_guncelle
      IMPORTING
        !iv_token     TYPE string
        !iv_operation TYPE string DEFAULT 'KAYIT'
        !is_request   TYPE ty_urun_kayit_req OPTIONAL
        !iv_raw_json  TYPE string OPTIONAL
      EXPORTING
        !es_result    TYPE ty_response .

    METHODS ithalat_bildirimi
      IMPORTING
        !iv_token    TYPE string
        !it_items    TYPE tt_ithalat_items OPTIONAL
        !iv_raw_json TYPE string OPTIONAL
      EXPORTING
        !es_result   TYPE ty_response .

    METHODS verme_bildirimi
      IMPORTING
        !iv_token        TYPE string
        !iv_essiz_kimlik TYPE abap_bool DEFAULT abap_false
        !it_items        TYPE tt_verme_items OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    METHODS alma_bildirimi
      IMPORTING
        !iv_token        TYPE string
        !iv_essiz_kimlik TYPE abap_bool DEFAULT abap_false
        !it_items        TYPE tt_alma_items OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    METHODS stok_sorgulama
      IMPORTING
        !iv_token    TYPE string
        !is_request  TYPE ty_stok_sorgu_req OPTIONAL
        !iv_raw_json TYPE string OPTIONAL
      EXPORTING
        !es_result   TYPE ty_response .

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA mo_http     TYPE REF TO if_http_client .
    DATA mv_dest     TYPE rfcdest .
    DATA mv_base_url TYPE string .
    DATA mv_use_dest TYPE abap_bool .

*---------------------------------------------------------------------*
*  JSON PARSE TİPLERİ (Log tablolarına alan çıkartmak için)
*---------------------------------------------------------------------*
    TYPES:
      BEGIN OF ty_req_urnsor,
        uno TYPE zuts_uno,
      END OF ty_req_urnsor .

    TYPES:
      BEGIN OF ty_req_urnkyt,
        uno       TYPE zuts_uno,
        urunadi   TYPE zuts_uradi,  " JSON: urunAdi (lower-case aware match)
        uruntipi  TYPE zuts_urtip,  " JSON: urunTipi
      END OF ty_req_urnkyt .

    TYPES:
      BEGIN OF ty_req_ithbld,
        uno TYPE zuts_uno,
        lno TYPE zuts_lno,
        sno TYPE zuts_sno,
        udi TYPE zuts_udi,
        adt TYPE zuts_adet,
        urt TYPE zuts_tarih,
        skt TYPE zuts_tarih,
        itt TYPE zuts_tarih,
        ieu TYPE zuts_ulke,
        meu TYPE zuts_ulke,
        gbn TYPE zuts_gbn,
      END OF ty_req_ithbld .

    TYPES:
      BEGIN OF ty_req_vrmbld,
        uno TYPE zuts_uno,
        lno TYPE zuts_lno,
        sno TYPE zuts_sno,
        udi TYPE zuts_udi,
        adt TYPE zuts_adet,
        kun TYPE zuts_kun,
        ben TYPE zuts_bedel,
        bno TYPE zuts_belno,
        git TYPE zuts_tarih,
      END OF ty_req_vrmbld .

    TYPES:
      BEGIN OF ty_req_almbld,
        uno TYPE zuts_uno,
        lno TYPE zuts_lno,
        sno TYPE zuts_sno,
        udi TYPE zuts_udi,
        adt TYPE zuts_adet,
        vbi TYPE zuts_vbi,
        gkk TYPE zuts_kun,
      END OF ty_req_almbld .

    TYPES:
      BEGIN OF ty_req_stksor,
        uno TYPE zuts_uno,
        lno TYPE zuts_lno,
        sno TYPE zuts_sno,
      END OF ty_req_stksor .

*---------------------------------------------------------------------*
*  YARDIMCI METODLAR
*---------------------------------------------------------------------*
    METHODS call_rest_service
      IMPORTING
        !iv_service_code TYPE string
        !iv_uri          TYPE string
        !iv_token        TYPE string
        !iv_payload      TYPE string
        !iv_operation    TYPE string OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE ty_response .

    METHODS serialize_to_json
      IMPORTING
        !ig_data       TYPE any
      RETURNING
        VALUE(rv_json) TYPE string .

    METHODS prepare_http_client
      IMPORTING
        !iv_full_url TYPE string
      RETURNING
        VALUE(rv_ok) TYPE abap_bool .

    "! Servise özel log tablosuna kayıt
    METHODS write_service_log
      IMPORTING
        !iv_service_code TYPE string
        !iv_endpoint     TYPE string
        !iv_request      TYPE string
        !iv_operation    TYPE string OPTIONAL
        !is_result       TYPE ty_response
        !iv_logid        TYPE sysuuid_c32 .

    "! Benzersiz LOGID üretir (32 char UUID)
    METHODS generate_logid
      RETURNING
        VALUE(rv_logid) TYPE sysuuid_c32 .

ENDCLASS.



CLASS zuts_cl001 IMPLEMENTATION.

*======================================================================*
*  CONSTRUCTOR
*======================================================================*
  METHOD constructor.
    mv_dest     = iv_dest.
    mv_use_dest = iv_destination_mode.
    mv_base_url = COND #( WHEN iv_env = 'PROD' THEN c_env-prod ELSE c_env-test ).
  ENDMETHOD.


*======================================================================*
*  HTTP CLIENT HAZIRLIĞI
*======================================================================*
  METHOD prepare_http_client.
    CLEAR rv_ok.

    IF mv_use_dest = abap_true AND mv_dest IS NOT INITIAL.
      cl_http_client=>create_by_destination(
        EXPORTING  destination = mv_dest
        IMPORTING  client      = mo_http
        EXCEPTIONS OTHERS      = 1 ).
    ELSE.
      cl_http_client=>create_by_url(
        EXPORTING  url    = iv_full_url
        IMPORTING  client = mo_http
        EXCEPTIONS OTHERS = 1 ).
    ENDIF.

    IF sy-subrc = 0 AND mo_http IS BOUND.
      rv_ok = abap_true.
    ENDIF.
  ENDMETHOD.


*======================================================================*
*  ORTAK REST ÇAĞRI ALTYAPISI
*======================================================================*
  METHOD call_rest_service.

    DATA lv_start TYPE i.
    DATA lv_end   TYPE i.

    GET RUN TIME FIELD lv_start.

    rs_result-logid = generate_logid( ).

    DATA(lv_full_url) = COND string( WHEN mv_use_dest = abap_true THEN iv_uri
                                     ELSE |{ mv_base_url }{ iv_uri }| ).

    IF prepare_http_client( lv_full_url ) = abap_false.
      rs_result-http_status = 0.
      rs_result-error_msg   = 'HTTP client olusturulamadi'.
      write_service_log(
        iv_service_code = iv_service_code
        iv_endpoint     = iv_uri
        iv_request      = iv_payload
        iv_operation    = iv_operation
        is_result       = rs_result
        iv_logid        = rs_result-logid ).
      RETURN.
    ENDIF.

    mo_http->request->set_method( if_http_request=>co_request_method_post ).

    IF mv_use_dest = abap_true.
      cl_http_utility=>set_request_uri(
        request = mo_http->request
        uri     = iv_uri ).
    ENDIF.

    mo_http->request->set_header_field( name = c_http-content_type  value = c_http-appl_json ).
    mo_http->request->set_header_field( name = c_http-accept        value = c_http-appl_json ).
    mo_http->request->set_header_field( name = c_http-authorization value = |{ c_http-bearer }{ iv_token }| ).

    mo_http->request->set_cdata( iv_payload ).

    mo_http->send( EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      rs_result-http_status = 0.
      rs_result-error_msg   = 'HTTP gonderim hatasi'.
      write_service_log(
        iv_service_code = iv_service_code
        iv_endpoint     = iv_uri
        iv_request      = iv_payload
        iv_operation    = iv_operation
        is_result       = rs_result
        iv_logid        = rs_result-logid ).
      RETURN.
    ENDIF.

    mo_http->receive( EXCEPTIONS OTHERS = 1 ).

    rs_result-response = mo_http->response->get_cdata( ).
    mo_http->response->get_status( IMPORTING code = rs_result-http_status ).

    IF rs_result-http_status BETWEEN 200 AND 299.
      rs_result-success_flag = abap_true.
    ELSE.
      rs_result-success_flag = abap_false.
      rs_result-error_msg    = rs_result-response.
    ENDIF.

    GET RUN TIME FIELD lv_end.
    rs_result-duration_ms = ( lv_end - lv_start ) / 1000.

    write_service_log(
      iv_service_code = iv_service_code
      iv_endpoint     = iv_uri
      iv_request      = iv_payload
      iv_operation    = iv_operation
      is_result       = rs_result
      iv_logid        = rs_result-logid ).

  ENDMETHOD.


*======================================================================*
*  JSON SERIALIZE
*======================================================================*
  METHOD serialize_to_json.
    TRY.
        rv_json = /ui2/cl_json=>serialize(
                    data        = ig_data
                    compress    = abap_true
                    pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
      CATCH cx_root.
        rv_json = ''.
    ENDTRY.
  ENDMETHOD.


*======================================================================*
*  LOGID ÜRETİMİ
*======================================================================*
  METHOD generate_logid.
    TRY.
        rv_logid = cl_system_uuid=>create_uuid_c32_static( ).
      CATCH cx_uuid_error.
        rv_logid = |{ sy-datum }{ sy-uzeit }{ sy-uname }{ sy-uzeit }|.
    ENDTRY.
  ENDMETHOD.


*======================================================================*
*  SERVİSE ÖZEL LOG YAZIMI (Dispatcher)
*======================================================================*
  METHOD write_service_log.

    DATA lv_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_ts.

    TRY.
        CASE iv_service_code.
*---------------------------------------------------------------------*
*  URUN SORGULAMA
*---------------------------------------------------------------------*
          WHEN c_srv-urun_sorgulama.
            DATA ls_parsed_urnsor TYPE ty_req_urnsor.
            TRY.
                /ui2/cl_json=>deserialize(
                  EXPORTING json = iv_request
                  CHANGING  data = ls_parsed_urnsor ).
              CATCH cx_root.
                CLEAR ls_parsed_urnsor.
            ENDTRY.

            DATA ls_urnsor TYPE zuts_log_urnsor.
            ls_urnsor-logid         = iv_logid.
            ls_urnsor-call_ts       = lv_ts.
            ls_urnsor-username      = sy-uname.
            ls_urnsor-endpoint      = iv_endpoint.
            ls_urnsor-http_status   = is_result-http_status.
            ls_urnsor-success_flag  = is_result-success_flag.
            ls_urnsor-duration_ms   = is_result-duration_ms.
            ls_urnsor-uno           = ls_parsed_urnsor-uno.
            ls_urnsor-request_json  = iv_request.
            ls_urnsor-response_json = is_result-response.
            ls_urnsor-error_msg     = is_result-error_msg.
            INSERT zuts_log_urnsor FROM ls_urnsor.

*---------------------------------------------------------------------*
*  URUN KAYIT / GUNCELLEME
*---------------------------------------------------------------------*
          WHEN c_srv-urun_kayit OR c_srv-urun_guncelle.
            DATA ls_parsed_urnkyt TYPE ty_req_urnkyt.
            TRY.
                /ui2/cl_json=>deserialize(
                  EXPORTING json        = iv_request
                            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                  CHANGING  data        = ls_parsed_urnkyt ).
              CATCH cx_root.
                CLEAR ls_parsed_urnkyt.
            ENDTRY.

            DATA ls_urnkyt TYPE zuts_log_urnkyt.
            ls_urnkyt-logid         = iv_logid.
            ls_urnkyt-call_ts       = lv_ts.
            ls_urnkyt-username      = sy-uname.
            ls_urnkyt-operation     = iv_operation.
            ls_urnkyt-endpoint      = iv_endpoint.
            ls_urnkyt-http_status   = is_result-http_status.
            ls_urnkyt-success_flag  = is_result-success_flag.
            ls_urnkyt-duration_ms   = is_result-duration_ms.
            ls_urnkyt-uno           = ls_parsed_urnkyt-uno.
            ls_urnkyt-urun_adi      = ls_parsed_urnkyt-urunadi.
            ls_urnkyt-urun_tipi     = ls_parsed_urnkyt-uruntipi.
            ls_urnkyt-request_json  = iv_request.
            ls_urnkyt-response_json = is_result-response.
            ls_urnkyt-error_msg     = is_result-error_msg.
            INSERT zuts_log_urnkyt FROM ls_urnkyt.

*---------------------------------------------------------------------*
*  ITHALAT BILDIRIMI
*---------------------------------------------------------------------*
          WHEN c_srv-ithalat_bildirimi.
            DATA ls_parsed_ith TYPE ty_req_ithbld.
            TRY.
                /ui2/cl_json=>deserialize(
                  EXPORTING json = iv_request
                  CHANGING  data = ls_parsed_ith ).
              CATCH cx_root.
                CLEAR ls_parsed_ith.
            ENDTRY.

            DATA ls_ith TYPE zuts_log_ithbld.
            ls_ith-logid         = iv_logid.
            ls_ith-call_ts       = lv_ts.
            ls_ith-username      = sy-uname.
            ls_ith-endpoint      = iv_endpoint.
            ls_ith-http_status   = is_result-http_status.
            ls_ith-success_flag  = is_result-success_flag.
            ls_ith-duration_ms   = is_result-duration_ms.
            ls_ith-uno           = ls_parsed_ith-uno.
            ls_ith-lno           = ls_parsed_ith-lno.
            ls_ith-sno           = ls_parsed_ith-sno.
            ls_ith-udi           = ls_parsed_ith-udi.
            ls_ith-adt           = ls_parsed_ith-adt.
            ls_ith-urt           = ls_parsed_ith-urt.
            ls_ith-skt           = ls_parsed_ith-skt.
            ls_ith-itt           = ls_parsed_ith-itt.
            ls_ith-ieu           = ls_parsed_ith-ieu.
            ls_ith-meu           = ls_parsed_ith-meu.
            ls_ith-gbn           = ls_parsed_ith-gbn.
            ls_ith-request_json  = iv_request.
            ls_ith-response_json = is_result-response.
            ls_ith-error_msg     = is_result-error_msg.
            INSERT zuts_log_ithbld FROM ls_ith.

*---------------------------------------------------------------------*
*  VERME BILDIRIMI
*---------------------------------------------------------------------*
          WHEN c_srv-verme_bildirimi.
            DATA ls_parsed_vrm TYPE ty_req_vrmbld.
            TRY.
                /ui2/cl_json=>deserialize(
                  EXPORTING json = iv_request
                  CHANGING  data = ls_parsed_vrm ).
              CATCH cx_root.
                CLEAR ls_parsed_vrm.
            ENDTRY.

            DATA ls_vrm TYPE zuts_log_vrmbld.
            ls_vrm-logid         = iv_logid.
            ls_vrm-call_ts       = lv_ts.
            ls_vrm-username      = sy-uname.
            ls_vrm-endpoint      = iv_endpoint.
            ls_vrm-http_status   = is_result-http_status.
            ls_vrm-success_flag  = is_result-success_flag.
            ls_vrm-duration_ms   = is_result-duration_ms.
            ls_vrm-uno           = ls_parsed_vrm-uno.
            ls_vrm-lno           = ls_parsed_vrm-lno.
            ls_vrm-sno           = ls_parsed_vrm-sno.
            ls_vrm-udi           = ls_parsed_vrm-udi.
            ls_vrm-adt           = ls_parsed_vrm-adt.
            ls_vrm-kun           = ls_parsed_vrm-kun.
            ls_vrm-ben           = ls_parsed_vrm-ben.
            ls_vrm-bno           = ls_parsed_vrm-bno.
            ls_vrm-git           = ls_parsed_vrm-git.
            ls_vrm-request_json  = iv_request.
            ls_vrm-response_json = is_result-response.
            ls_vrm-error_msg     = is_result-error_msg.
            INSERT zuts_log_vrmbld FROM ls_vrm.

*---------------------------------------------------------------------*
*  ALMA BILDIRIMI
*---------------------------------------------------------------------*
          WHEN c_srv-alma_bildirimi.
            DATA ls_parsed_alm TYPE ty_req_almbld.
            TRY.
                /ui2/cl_json=>deserialize(
                  EXPORTING json = iv_request
                  CHANGING  data = ls_parsed_alm ).
              CATCH cx_root.
                CLEAR ls_parsed_alm.
            ENDTRY.

            DATA ls_alm TYPE zuts_log_almbld.
            ls_alm-logid         = iv_logid.
            ls_alm-call_ts       = lv_ts.
            ls_alm-username      = sy-uname.
            ls_alm-endpoint      = iv_endpoint.
            ls_alm-http_status   = is_result-http_status.
            ls_alm-success_flag  = is_result-success_flag.
            ls_alm-duration_ms   = is_result-duration_ms.
            ls_alm-uno           = ls_parsed_alm-uno.
            ls_alm-lno           = ls_parsed_alm-lno.
            ls_alm-sno           = ls_parsed_alm-sno.
            ls_alm-udi           = ls_parsed_alm-udi.
            ls_alm-adt           = ls_parsed_alm-adt.
            ls_alm-vbi           = ls_parsed_alm-vbi.
            ls_alm-gkk           = ls_parsed_alm-gkk.
            ls_alm-request_json  = iv_request.
            ls_alm-response_json = is_result-response.
            ls_alm-error_msg     = is_result-error_msg.
            INSERT zuts_log_almbld FROM ls_alm.

*---------------------------------------------------------------------*
*  STOK SORGULAMA
*---------------------------------------------------------------------*
          WHEN c_srv-stok_sorgulama.
            DATA ls_parsed_stk TYPE ty_req_stksor.
            TRY.
                /ui2/cl_json=>deserialize(
                  EXPORTING json = iv_request
                  CHANGING  data = ls_parsed_stk ).
              CATCH cx_root.
                CLEAR ls_parsed_stk.
            ENDTRY.

            DATA ls_stk TYPE zuts_log_stksor.
            ls_stk-logid         = iv_logid.
            ls_stk-call_ts       = lv_ts.
            ls_stk-username      = sy-uname.
            ls_stk-endpoint      = iv_endpoint.
            ls_stk-http_status   = is_result-http_status.
            ls_stk-success_flag  = is_result-success_flag.
            ls_stk-duration_ms   = is_result-duration_ms.
            ls_stk-uno           = ls_parsed_stk-uno.
            ls_stk-lno           = ls_parsed_stk-lno.
            ls_stk-sno           = ls_parsed_stk-sno.
            ls_stk-request_json  = iv_request.
            ls_stk-response_json = is_result-response.
            ls_stk-error_msg     = is_result-error_msg.
            INSERT zuts_log_stksor FROM ls_stk.

        ENDCASE.

        COMMIT WORK.

      CATCH cx_root.
        " Log yazım hatası sessiz geçilir — ana akışı bozmaz
    ENDTRY.

  ENDMETHOD.


*======================================================================*
*  1) ÜRÜN SORGULAMA SERVİSİ
*======================================================================*
  METHOD urun_sorgulama.

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( is_request ) ).

    es_result = call_rest_service(
                  iv_service_code = c_srv-urun_sorgulama
                  iv_uri          = c_uri-urun_sorgulama
                  iv_token        = iv_token
                  iv_payload      = lv_json ).

  ENDMETHOD.


*======================================================================*
*  2) ÜRÜN KAYIT / GÜNCELLEME SERVİSİ
*======================================================================*
  METHOD urun_kayit_guncelle.

    DATA(lv_uri) = COND string(
       WHEN iv_operation = 'GUNCELLE' THEN c_uri-urun_guncelle
       ELSE c_uri-urun_kayit ).

    DATA(lv_srv_code) = COND string(
       WHEN iv_operation = 'GUNCELLE' THEN c_srv-urun_guncelle
       ELSE c_srv-urun_kayit ).

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL           THEN iv_raw_json
       WHEN is_request-ham_json IS NOT INITIAL   THEN is_request-ham_json
       ELSE serialize_to_json( is_request ) ).

    es_result = call_rest_service(
                  iv_service_code = lv_srv_code
                  iv_uri          = lv_uri
                  iv_token        = iv_token
                  iv_payload      = lv_json
                  iv_operation    = iv_operation ).

  ENDMETHOD.


*======================================================================*
*  3) İTHALAT BİLDİRİMİ SERVİSİ
*======================================================================*
  METHOD ithalat_bildirimi.

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( it_items ) ).

    es_result = call_rest_service(
                  iv_service_code = c_srv-ithalat_bildirimi
                  iv_uri          = c_uri-ithalat_bildirimi
                  iv_token        = iv_token
                  iv_payload      = lv_json ).

  ENDMETHOD.


*======================================================================*
*  4) VERME (SATIŞ) BİLDİRİMİ SERVİSİ
*======================================================================*
  METHOD verme_bildirimi.

    DATA(lv_uri) = COND string(
       WHEN iv_essiz_kimlik = abap_true THEN c_uri-verme_essiz_kimlik
       ELSE c_uri-verme_bildirimi ).

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( it_items ) ).

    es_result = call_rest_service(
                  iv_service_code = c_srv-verme_bildirimi
                  iv_uri          = lv_uri
                  iv_token        = iv_token
                  iv_payload      = lv_json ).

  ENDMETHOD.


*======================================================================*
*  5) ALMA (KABUL) BİLDİRİMİ SERVİSİ
*======================================================================*
  METHOD alma_bildirimi.

    DATA(lv_uri) = COND string(
       WHEN iv_essiz_kimlik = abap_true THEN c_uri-alma_essiz_kimlik
       ELSE c_uri-alma_bildirimi ).

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( it_items ) ).

    es_result = call_rest_service(
                  iv_service_code = c_srv-alma_bildirimi
                  iv_uri          = lv_uri
                  iv_token        = iv_token
                  iv_payload      = lv_json ).

  ENDMETHOD.


*======================================================================*
*  6) STOK SORGULAMA SERVİSİ
*======================================================================*
  METHOD stok_sorgulama.

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( is_request ) ).

    es_result = call_rest_service(
                  iv_service_code = c_srv-stok_sorgulama
                  iv_uri          = c_uri-stok_sorgulama
                  iv_token        = iv_token
                  iv_payload      = lv_json ).

  ENDMETHOD.

ENDCLASS.
