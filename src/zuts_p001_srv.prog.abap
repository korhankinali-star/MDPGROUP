*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_SRV
*&---------------------------------------------------------------------*
*& Servis runner + PDF'ten alinan dummy veri saglayicisi
*&
*& LCL_SERVICE_RUNNER artik response'u parse edip servis tipine gore
*& farkli row tablosu doldurur:
*&   - URUN servisleri   -> tt_urun_rows
*&   - BILDIRIM servisleri-> tt_bildirim_rows  (ithalat/verme/alma)
*&   - STOK servisi      -> tt_stok_rows
*& LCL_ALV_VIEW bunlari dinamik olarak uygun kolonlarla gosterir.
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

*---------------------------------------------------------------------*
*  SUMMARY (ortak baslik bilgisi)
*---------------------------------------------------------------------*
    TYPES:
      BEGIN OF ty_run_result,
        service_code  TYPE string,
        service_name  TYPE string,
        view_type     TYPE string,   " URUN / BILDIRIM / STOK
        endpoint      TYPE string,
        http_status   TYPE i,
        success_flag  TYPE abap_bool,
        success_icon  TYPE icon_d,
        duration_ms   TYPE i,
        sonuc_kodu    TYPE string,
        sonuc_mesaji  TYPE string,
        snc_id        TYPE string,
        error_msg     TYPE string,
      END OF ty_run_result .

*---------------------------------------------------------------------*
*  1) URUN SORGULAMA / URUN KAYIT - Donen urun detaylari
*---------------------------------------------------------------------*
    TYPES:
      BEGIN OF ty_urun_row,
        urun_no       TYPE string,   " birincilUrunNumarasi
        urun_adi      TYPE string,   " etiketAdi
        marka         TYPE string,   " markaAdi
        model         TYPE string,   " versiyonModel
        urun_tipi     TYPE string,   " urunTipi
        sinif         TYPE string,   " sinif
        yonetmelik    TYPE string,   " yonetmelik
        ithal_imal    TYPE string,   " ithalImalBilgisi
        kayit_durumu  TYPE string,   " kayitDurumu
        uretici_firma TYPE string,   " ureticiFirma
        mensei        TYPE string,   " menseiUlkeSet
      END OF ty_urun_row .
    TYPES tt_urun_rows TYPE STANDARD TABLE OF ty_urun_row WITH DEFAULT KEY .

*---------------------------------------------------------------------*
*  2) BILDIRIM SERVISLERI - Donen mesaj listesi
*---------------------------------------------------------------------*
    TYPES:
      BEGIN OF ty_bildirim_row,
        mesaj_tipi  TYPE string,   " MSJ.TIP - BILGI / HATA / UYARI
        mesaj_ikon  TYPE icon_d,
        mesaj_kodu  TYPE string,   " MSJ.KOD
        mesaj_metni TYPE string,   " MSJ.MET
        parametre   TYPE string,   " MSJ.MPA (join)
        snc_id      TYPE string,   " SNC (her satira kopyalanir)
      END OF ty_bildirim_row .
    TYPES tt_bildirim_rows TYPE STANDARD TABLE OF ty_bildirim_row WITH DEFAULT KEY .

*---------------------------------------------------------------------*
*  3) STOK SORGULAMA - Donen stok kayitlari
*---------------------------------------------------------------------*
    TYPES:
      BEGIN OF ty_stok_row,
        urun_no        TYPE string,   " UNO
        lot_no         TYPE string,   " LNO
        seri_no        TYPE string,   " SNO
        adet           TYPE i,        " ADT
        marka          TYPE string,   " MRK
        uretici_no     TYPE string,   " UIK
        uretici_unvan  TYPE string,   " UIU
        uretim_tarihi  TYPE string,   " URT
        son_kullanma   TYPE string,   " SKT
      END OF ty_stok_row .
    TYPES tt_stok_rows TYPE STANDARD TABLE OF ty_stok_row WITH DEFAULT KEY .

*---------------------------------------------------------------------*
*  View tipi sabitleri
*---------------------------------------------------------------------*
    CONSTANTS:
      BEGIN OF c_view,
        urun     TYPE string VALUE 'URUN' ##NO_TEXT,
        bildirim TYPE string VALUE 'BILDIRIM' ##NO_TEXT,
        stok     TYPE string VALUE 'STOK' ##NO_TEXT,
      END OF c_view .

    METHODS constructor
      IMPORTING
        !iv_env   TYPE string
        !iv_dest  TYPE rfcdest
        !iv_token TYPE string.

    METHODS run
      IMPORTING
        !iv_service_code  TYPE string
        !iv_use_dummy     TYPE abap_bool
      EXPORTING
        !es_summary       TYPE ty_run_result
        !et_urun_rows     TYPE tt_urun_rows
        !et_bildirim_rows TYPE tt_bildirim_rows
        !et_stok_rows     TYPE tt_stok_rows.

  PRIVATE SECTION.

    DATA mo_client TYPE REF TO zuts_cl001.
    DATA mv_token  TYPE string.

*---------------------------------------------------------------------*
*  RESPONSE PARSE TIPLERI (deserialize hedefi)
*---------------------------------------------------------------------*
    TYPES:
      BEGIN OF ty_urun_detay,
        birincilurunnumarasi TYPE string,
        etiketadi            TYPE string,
        markaadi             TYPE string,
        versiyonmodel        TYPE string,
        uruntipi             TYPE string,
        sinif                TYPE string,
        yonetmelik           TYPE string,
        ithalimalbilgisi     TYPE string,
        kayitdurumu          TYPE string,
        ureticifirma         TYPE string,
        menseiulkeset        TYPE string,
      END OF ty_urun_detay .
    TYPES:
      BEGIN OF ty_resp_urun,
        sonuc         TYPE i,
        sonucmesaji   TYPE string,
        urundetaylist TYPE STANDARD TABLE OF ty_urun_detay WITH DEFAULT KEY,
      END OF ty_resp_urun .

    TYPES:
      BEGIN OF ty_msj_item,
        met TYPE string,
        kod TYPE string,
        tip TYPE string,
        mpa TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      END OF ty_msj_item .
    TYPES:
      BEGIN OF ty_resp_bildirim,
        snc TYPE string,
        msj TYPE STANDARD TABLE OF ty_msj_item WITH DEFAULT KEY,
      END OF ty_resp_bildirim .

    TYPES:
      BEGIN OF ty_stok_item,
        uno TYPE string,
        lno TYPE string,
        sno TYPE string,
        adt TYPE i,
        mrk TYPE string,
        uik TYPE string,
        uiu TYPE string,
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

    METHODS parse_urun_response
      IMPORTING
        !iv_response TYPE string
      EXPORTING
        !et_rows     TYPE tt_urun_rows
      CHANGING
        !cs_summary  TYPE ty_run_result.

    METHODS parse_bildirim_response
      IMPORTING
        !iv_response TYPE string
      EXPORTING
        !et_rows     TYPE tt_bildirim_rows
      CHANGING
        !cs_summary  TYPE ty_run_result.

    METHODS parse_stok_response
      IMPORTING
        !iv_response TYPE string
      EXPORTING
        !et_rows     TYPE tt_stok_rows
      CHANGING
        !cs_summary  TYPE ty_run_result.

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
*  URUN RESPONSE PARSE
*======================================================================*
  METHOD parse_urun_response.

    CLEAR et_rows.

    DATA ls_parsed TYPE ty_resp_urun.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json        = iv_response
                    pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING  data        = ls_parsed ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    cs_summary-sonuc_kodu   = |{ ls_parsed-sonuc }|.
    cs_summary-sonuc_mesaji = ls_parsed-sonucmesaji.

    LOOP AT ls_parsed-urundetaylist ASSIGNING FIELD-SYMBOL(<ls_ud>).
      APPEND VALUE #(
        urun_no       = <ls_ud>-birincilurunnumarasi
        urun_adi      = <ls_ud>-etiketadi
        marka         = <ls_ud>-markaadi
        model         = <ls_ud>-versiyonmodel
        urun_tipi     = <ls_ud>-uruntipi
        sinif         = <ls_ud>-sinif
        yonetmelik    = <ls_ud>-yonetmelik
        ithal_imal    = <ls_ud>-ithalimalbilgisi
        kayit_durumu  = <ls_ud>-kayitdurumu
        uretici_firma = <ls_ud>-ureticifirma
        mensei        = <ls_ud>-menseiulkeset ) TO et_rows.
    ENDLOOP.

  ENDMETHOD.


*======================================================================*
*  BILDIRIM RESPONSE PARSE
*======================================================================*
  METHOD parse_bildirim_response.

    CLEAR et_rows.

    DATA ls_parsed TYPE ty_resp_bildirim.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = iv_response
          CHANGING  data = ls_parsed ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    cs_summary-snc_id = ls_parsed-snc.

    IF lines( ls_parsed-msj ) > 0.
      READ TABLE ls_parsed-msj INDEX 1 INTO DATA(ls_first).
      cs_summary-sonuc_kodu   = ls_first-kod.
      cs_summary-sonuc_mesaji = ls_first-met.
    ENDIF.

    LOOP AT ls_parsed-msj ASSIGNING FIELD-SYMBOL(<ls_msj>).
      DATA(lv_params) = concat_lines_of( table = <ls_msj>-mpa sep = `, ` ).

      DATA(lv_icon) = SWITCH icon_d( <ls_msj>-tip
                        WHEN 'BILGI'  THEN icon_led_green
                        WHEN 'UYARI'  THEN icon_led_yellow
                        WHEN 'HATA'   THEN icon_led_red
                        ELSE icon_led_inactive ).

      APPEND VALUE #(
        mesaj_tipi  = <ls_msj>-tip
        mesaj_ikon  = lv_icon
        mesaj_kodu  = <ls_msj>-kod
        mesaj_metni = <ls_msj>-met
        parametre   = lv_params
        snc_id      = ls_parsed-snc ) TO et_rows.
    ENDLOOP.

  ENDMETHOD.


*======================================================================*
*  STOK RESPONSE PARSE
*======================================================================*
  METHOD parse_stok_response.

    CLEAR et_rows.

    DATA ls_parsed TYPE ty_resp_stok.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = iv_response
          CHANGING  data = ls_parsed ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    LOOP AT ls_parsed-snc-lst ASSIGNING FIELD-SYMBOL(<ls_stk>).
      APPEND VALUE #(
        urun_no       = <ls_stk>-uno
        lot_no        = <ls_stk>-lno
        seri_no       = <ls_stk>-sno
        adet          = <ls_stk>-adt
        marka         = <ls_stk>-mrk
        uretici_no    = <ls_stk>-uik
        uretici_unvan = <ls_stk>-uiu
        uretim_tarihi = <ls_stk>-urt
        son_kullanma  = <ls_stk>-skt ) TO et_rows.
    ENDLOOP.

    IF lines( et_rows ) > 0.
      cs_summary-sonuc_kodu   = 'OK'.
      cs_summary-sonuc_mesaji = |{ lines( et_rows ) } stok kaydi bulundu|.
    ELSE.
      cs_summary-sonuc_mesaji = 'Stok kaydi bulunamadi'.
    ENDIF.

  ENDMETHOD.


*======================================================================*
*  ANA METOD: RUN
*======================================================================*
  METHOD run.

    CLEAR: es_summary, et_urun_rows, et_bildirim_rows, et_stok_rows.

    DATA ls_resp         TYPE zuts_cl001=>ty_response.
    DATA lv_request_json TYPE string.

    GET RUN TIME FIELD DATA(lv_start).

    es_summary-service_code = iv_service_code.

    CASE iv_service_code.
      WHEN 'URUN_SORGULAMA'.
        es_summary-service_name = 'Urun Sorgulama'.
        es_summary-endpoint     = zuts_cl001=>c_uri-urun_sorgulama.
        es_summary-view_type    = c_view-urun.
      WHEN 'URUN_KAYIT_GUNCELLE'.
        es_summary-service_name = 'Urun Kayit / Guncelleme'.
        es_summary-endpoint     = zuts_cl001=>c_uri-urun_kayit.
        es_summary-view_type    = c_view-urun.
      WHEN 'ITHALAT_BILDIRIMI'.
        es_summary-service_name = 'Ithalat Bildirimi'.
        es_summary-endpoint     = zuts_cl001=>c_uri-ithalat_bildirimi.
        es_summary-view_type    = c_view-bildirim.
      WHEN 'VERME_BILDIRIMI'.
        es_summary-service_name = 'Verme (Satis) Bildirimi'.
        es_summary-endpoint     = zuts_cl001=>c_uri-verme_bildirimi.
        es_summary-view_type    = c_view-bildirim.
      WHEN 'ALMA_BILDIRIMI'.
        es_summary-service_name = 'Alma (Kabul) Bildirimi'.
        es_summary-endpoint     = zuts_cl001=>c_uri-alma_bildirimi.
        es_summary-view_type    = c_view-bildirim.
      WHEN 'STOK_SORGULAMA'.
        es_summary-service_name = 'Stok Sorgulama'.
        es_summary-endpoint     = zuts_cl001=>c_uri-stok_sorgulama.
        es_summary-view_type    = c_view-stok.
      WHEN OTHERS.
        es_summary-service_name = 'Gecersiz Servis'.
        es_summary-error_msg    = |Bilinmeyen servis kodu: { iv_service_code }|.
        es_summary-success_icon = icon_led_red.
        RETURN.
    ENDCASE.

    IF iv_use_dummy = abap_true.
      lv_request_json = build_dummy_req( iv_service_code ).
    ENDIF.

    IF mo_client IS NOT BOUND.
      es_summary-error_msg    = 'HTTP istemcisi hazir degil'.
      es_summary-success_icon = icon_led_red.
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
    es_summary-duration_ms = ( lv_end - lv_start ) / 1000.

    es_summary-http_status  = ls_resp-http_status.
    es_summary-success_flag = ls_resp-success_flag.
    es_summary-error_msg    = ls_resp-error_msg.
    es_summary-success_icon = COND #( WHEN ls_resp-success_flag = abap_true
                                        THEN icon_led_green
                                        ELSE icon_led_red ).

    " View tipine gore response'u parse et
    CASE es_summary-view_type.
      WHEN c_view-urun.
        parse_urun_response(
          EXPORTING iv_response = ls_resp-response
          IMPORTING et_rows     = et_urun_rows
          CHANGING  cs_summary  = es_summary ).

      WHEN c_view-bildirim.
        parse_bildirim_response(
          EXPORTING iv_response = ls_resp-response
          IMPORTING et_rows     = et_bildirim_rows
          CHANGING  cs_summary  = es_summary ).

      WHEN c_view-stok.
        parse_stok_response(
          EXPORTING iv_response = ls_resp-response
          IMPORTING et_rows     = et_stok_rows
          CHANGING  cs_summary  = es_summary ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
