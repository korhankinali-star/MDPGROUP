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
      END OF ty_response .

    "! 1) Ürün Sorgulama Request Alanları
    "! Ref: 3.1 Ürün Sorgulama Servisi Veri Alanları (PDF s. 12416+)
    TYPES:
      BEGIN OF ty_urun_sorgu_req,
        urun_numarasi    TYPE string,  "! UNO - Ürün Numarası / Barkod (Metin 23)
        essiz_kimlik     TYPE string,  "! UDI - Eşsiz Kimlik (Opsiyonel)
        lot_numarasi     TYPE string,  "! LNO - Lot/Batch Numarası
        seri_numarasi    TYPE string,  "! SNO - Seri/Sıra Numarası
      END OF ty_urun_sorgu_req .

    "! 2) Ürün Kayıt/Güncelleme Request Alanları
    TYPES:
      BEGIN OF ty_urun_kayit_req,
        urun_numarasi    TYPE string,  "! UNO - Ürün Numarası (Zorunlu)
        urun_tipi        TYPE string,  "! UTP - TIBBI_CIHAZ, ISMARLAMA_TIBBI_CIHAZ
        urun_adi         TYPE string,  "! Ürün Adı
        uretici_firma    TYPE string,  "! Üretici Firma Kodu
        lot_takipli      TYPE abap_bool, "! Lot takipli mi
        seri_takipli     TYPE abap_bool, "! Seri takipli mi
        sinif            TYPE string,  "! Tıbbi Cihaz Sınıfı
        ek3_kapsaminda   TYPE string,  "! EVET / HAYIR
        raf_omru         TYPE i,       "! Raf Ömrü
        raf_omru_birimi  TYPE string,  "! GUN / AY / YIL
        ham_json         TYPE string,  "! Alternatif: ham JSON verilebilir
      END OF ty_urun_kayit_req .

    "! 3) İthalat Bildirimi Request Alanları
    "! Ref: 3.1.2 İthalat Bildirimi Veri Alanları (PDF s. 1411+)
    TYPES:
      BEGIN OF ty_ithalat_item,
        uno TYPE string,       "! Ürün Numarası (Metin 23, Zorunlu)
        lno TYPE string,       "! Lot/Batch Numarası (Metin 20, Koşullu)
        sno TYPE string,       "! Seri/Sıra Numarası (Metin 20, Koşullu)
        urt TYPE string,       "! Üretim Tarihi YYYY-AA-GG (Zorunlu)
        skt TYPE string,       "! Son Kullanma Tarihi YYYY-AA-GG SS
        itt TYPE string,       "! İthalat Tarihi YYYY-AA-GG
        adt TYPE i,            "! Adet (Lot bazlı ürünler için)
        udi TYPE string,       "! Eşsiz Kimlik (UDI / Karekod)
        ieu TYPE n LENGTH 3,   "! İthal Edildiği Ülke Kodu (Zorunlu)
        meu TYPE n LENGTH 3,   "! Menşei Ülke Kodu (Zorunlu)
        gbn TYPE string,       "! Gümrük Beyanname Numarası (Metin 16)
      END OF ty_ithalat_item .
    TYPES tt_ithalat_items TYPE STANDARD TABLE OF ty_ithalat_item WITH DEFAULT KEY .

    "! 4) Verme (Satış) Bildirimi Request Alanları
    "! Ref: 3.1.4 Verme Bildirimi Veri Alanları (PDF s. 1774+)
    TYPES:
      BEGIN OF ty_verme_item,
        uno          TYPE string,  "! Ürün Numarası (Zorunlu)
        lno          TYPE string,  "! Lot/Batch
        sno          TYPE string,  "! Seri Numarası
        adt          TYPE i,       "! Adet
        udi          TYPE string,  "! Eşsiz Kimlik (essizKimlik endpoint için)
        alan_kurum   TYPE string,  "! KUN - Alan Kurum (Kurum Tanımlayıcı)
        ben          TYPE string,  "! BEN - Bedelli / Bedelsiz (YES/NO)
        gbn          TYPE string,  "! GBN - Belge No
        itt          TYPE string,  "! İşlem Tarihi
      END OF ty_verme_item .
    TYPES tt_verme_items TYPE STANDARD TABLE OF ty_verme_item WITH DEFAULT KEY .

    "! 5) Alma (Kabul) Bildirimi Request Alanları
    "! Ref: 3.1.6 Alma Bildirimi Veri Alanları (PDF s. 2011+)
    TYPES:
      BEGIN OF ty_alma_item,
        uno          TYPE string,
        lno          TYPE string,
        sno          TYPE string,
        adt          TYPE i,
        udi          TYPE string,
        veren_kurum  TYPE string,  "! VKN - Veren Kurum
        itt          TYPE string,  "! İşlem Tarihi
        gbn          TYPE string,  "! Belge No
      END OF ty_alma_item .
    TYPES tt_alma_items TYPE STANDARD TABLE OF ty_alma_item WITH DEFAULT KEY .

    "! 6) Stok Sorgulama Request Alanları
    "! Ref: 3.2 Stok Sorgulama (stokYapilabilirTekilUrun/sorgula, PDF s. 10011+)
    TYPES:
      BEGIN OF ty_stok_sorgu_req,
        urun_numarasi TYPE string,    "! UNO
        essiz_kimlik  TYPE string,    "! UDI (opsiyonel)
        lot_numarasi  TYPE string,
        seri_numarasi TYPE string,
        offset        TYPE i,         "! Kayıt sayısı parametresi ile sorgulama
        limit         TYPE i,
      END OF ty_stok_sorgu_req .

*---------------------------------------------------------------------*
*  CONSTRUCTOR
*---------------------------------------------------------------------*
    METHODS constructor
      IMPORTING
        !iv_dest   TYPE rfcdest   OPTIONAL
        !iv_env    TYPE string    DEFAULT 'TEST'   " 'PROD' veya 'TEST'
        !iv_destination_mode TYPE abap_bool DEFAULT abap_false.

*---------------------------------------------------------------------*
*  SERVİS METODLARI
*---------------------------------------------------------------------*
    "! 1) Ürün Sorgulama Servisi
    METHODS urun_sorgulama
      IMPORTING
        !iv_token        TYPE string
        !is_request      TYPE ty_urun_sorgu_req OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    "! 2) Ürün Kayıt / Güncelleme Servisi
    "! iv_operation: 'KAYIT' (yeni ürün) veya 'GUNCELLE' (mevcut ürün)
    METHODS urun_kayit_guncelle
      IMPORTING
        !iv_token        TYPE string
        !iv_operation    TYPE string DEFAULT 'KAYIT'
        !is_request      TYPE ty_urun_kayit_req OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    "! 3) İthalat Bildirimi Servisi
    METHODS ithalat_bildirimi
      IMPORTING
        !iv_token        TYPE string
        !it_items        TYPE tt_ithalat_items OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    "! 4) Verme (Satış) Bildirimi Servisi
    "! iv_essiz_kimlik = abap_true ise /essizKimlik endpoint kullanılır
    METHODS verme_bildirimi
      IMPORTING
        !iv_token        TYPE string
        !iv_essiz_kimlik TYPE abap_bool DEFAULT abap_false
        !it_items        TYPE tt_verme_items OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    "! 5) Alma (Kabul) Bildirimi Servisi
    METHODS alma_bildirimi
      IMPORTING
        !iv_token        TYPE string
        !iv_essiz_kimlik TYPE abap_bool DEFAULT abap_false
        !it_items        TYPE tt_alma_items OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

    "! 6) Stok Sorgulama Servisi
    METHODS stok_sorgulama
      IMPORTING
        !iv_token        TYPE string
        !is_request      TYPE ty_stok_sorgu_req OPTIONAL
        !iv_raw_json     TYPE string OPTIONAL
      EXPORTING
        !es_result       TYPE ty_response .

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA mo_http        TYPE REF TO if_http_client .
    DATA mv_dest        TYPE rfcdest .
    DATA mv_base_url    TYPE string .
    DATA mv_use_dest    TYPE abap_bool .

    "! HTTP POST çağrısı (ortak altyapı)
    METHODS call_rest_service
      IMPORTING
        !iv_uri         TYPE string
        !iv_token       TYPE string
        !iv_payload     TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_response .

    "! JSON serialization
    METHODS serialize_to_json
      IMPORTING
        !ig_data TYPE any
      RETURNING
        VALUE(rv_json) TYPE string .

    "! UTS Log tablosuna yazım
    METHODS write_log
      IMPORTING
        !iv_endpoint TYPE string
        !iv_request  TYPE string
        !is_result   TYPE ty_response .

    "! HTTP client'ı hazırlar (destination veya URL bazlı)
    METHODS prepare_http_client
      IMPORTING
        !iv_full_url  TYPE string
      RETURNING
        VALUE(rv_ok)  TYPE abap_bool .

ENDCLASS.



CLASS zuts_cl001 IMPLEMENTATION.

  METHOD constructor.
    mv_dest     = iv_dest.
    mv_use_dest = iv_destination_mode.
    mv_base_url = COND #( WHEN iv_env = 'PROD' THEN c_env-prod ELSE c_env-test ).
  ENDMETHOD.


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


  METHOD call_rest_service.

    DATA(lv_full_url) = COND string( WHEN mv_use_dest = abap_true THEN iv_uri
                                     ELSE |{ mv_base_url }{ iv_uri }| ).

    IF prepare_http_client( lv_full_url ) = abap_false.
      rs_result-http_status = 0.
      rs_result-error_msg   = 'HTTP client olusturulamadi'.
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

    write_log( iv_endpoint = iv_uri
               iv_request  = iv_payload
               is_result   = rs_result ).

  ENDMETHOD.


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


  METHOD write_log.
    DATA ls_log TYPE zuts_log.

    TRY.
        ls_log-logid       = |{ sy-datum }{ sy-uzeit }{ sy-uname }{ sy-uzeit }|.
        ls_log-username    = sy-uname.
        GET TIME STAMP FIELD ls_log-called_at.
        ls_log-endpoint    = iv_endpoint.
        ls_log-request     = iv_request.
        ls_log-response    = is_result-response.
        ls_log-http_status = is_result-http_status.
        ls_log-error_msg   = is_result-error_msg.

        INSERT zuts_log FROM ls_log.
        COMMIT WORK.
      CATCH cx_root.
        " Log yazım hatası sessiz geçilir
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
                  iv_uri     = c_uri-urun_sorgulama
                  iv_token   = iv_token
                  iv_payload = lv_json ).

  ENDMETHOD.


*======================================================================*
*  2) ÜRÜN KAYIT / GÜNCELLEME SERVİSİ
*======================================================================*
  METHOD urun_kayit_guncelle.

    DATA(lv_uri) = COND string(
       WHEN iv_operation = 'GUNCELLE' THEN c_uri-urun_guncelle
       ELSE c_uri-urun_kayit ).

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       WHEN is_request-ham_json IS NOT INITIAL THEN is_request-ham_json
       ELSE serialize_to_json( is_request ) ).

    es_result = call_rest_service(
                  iv_uri     = lv_uri
                  iv_token   = iv_token
                  iv_payload = lv_json ).

  ENDMETHOD.


*======================================================================*
*  3) İTHALAT BİLDİRİMİ SERVİSİ
*======================================================================*
  METHOD ithalat_bildirimi.

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( it_items ) ).

    es_result = call_rest_service(
                  iv_uri     = c_uri-ithalat_bildirimi
                  iv_token   = iv_token
                  iv_payload = lv_json ).

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
                  iv_uri     = lv_uri
                  iv_token   = iv_token
                  iv_payload = lv_json ).

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
                  iv_uri     = lv_uri
                  iv_token   = iv_token
                  iv_payload = lv_json ).

  ENDMETHOD.


*======================================================================*
*  6) STOK SORGULAMA SERVİSİ
*======================================================================*
  METHOD stok_sorgulama.

    DATA(lv_json) = COND string(
       WHEN iv_raw_json IS NOT INITIAL THEN iv_raw_json
       ELSE serialize_to_json( is_request ) ).

    es_result = call_rest_service(
                  iv_uri     = c_uri-stok_sorgulama
                  iv_token   = iv_token
                  iv_payload = lv_json ).

  ENDMETHOD.

ENDCLASS.
