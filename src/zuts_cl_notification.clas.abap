CLASS zuts_cl_notification DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA gs_likp TYPE likp .
    DATA gt_lips TYPE tt_lips .
    DATA gv_fpath TYPE string .
    DATA gt_output TYPE zuts_t_import .
    DATA gs_output TYPE zuts_s_import .
    DATA gt_outsales TYPE zuts_t_sales .
    DATA gs_outsales TYPE zuts_s_sales .
    DATA gv_stcd1 TYPE stcd1 .

    CLASS-METHODS class_constructor .
    METHODS constructor
      IMPORTING
        !iv_langu TYPE syst_langu .
    METHODS get_delivery_data
      IMPORTING
        !iv_vbeln         TYPE vbeln_vl
      RETURNING
        VALUE(rv_retcode) TYPE sy-subrc .
    METHODS build_data_output_ztro .
    METHODS build_data_output_ztri .
    METHODS download_data
      IMPORTING
        !iv_kschl TYPE kschl .
    METHODS download_data_per_line
      IMPORTING
        !iv_kschl TYPE kschl .
    METHODS return_message .
    CLASS-METHODS check_output_routine
      IMPORTING
        !iv_wbstk       TYPE wbstk
      RETURNING
        VALUE(rv_subrc) TYPE syst_subrc .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_serial,
        posnr TYPE posnr,
        obknr TYPE objknr,
        sernr TYPE gernr,
        matnr TYPE matnr,
      END OF ty_serial .
    TYPES:
      BEGIN OF ty_material,
        matnr TYPE matnr,
        ean11 TYPE ean11,
        maktx TYPE maktx,
      END OF ty_material .
    TYPES:
      BEGIN OF ty_mch1,
        matnr   TYPE matnr,
        charg   TYPE charg_d,
        herkl   TYPE herkl,
        landx50 TYPE landx50,
      END OF ty_mch1 .
    TYPES:
      BEGIN OF ty_ctry,
        lifnr   TYPE lifnr,
        land1   TYPE land1,
        landx50 TYPE landx50,
      END OF ty_ctry .
    TYPES:
      BEGIN OF ty_pstyv,
        pstyv TYPE c LENGTH 5,
      END OF ty_pstyv .
    TYPES:
      tt_serial   TYPE TABLE OF ty_serial .
    TYPES:
      tt_material TYPE TABLE OF ty_material .
    TYPES:
      tt_mch1     TYPE TABLE OF ty_mch1 .
    TYPES:
      tt_ctry     TYPE TABLE OF ty_ctry .
    TYPES:
      tt_pstyv    TYPE TABLE OF ty_pstyv .

    DATA lv_pstyv TYPE pstyv .
    DATA lt_allowed_pstyv TYPE tt_pstyv .
    DATA ls_allowed_pstyv TYPE ty_pstyv .
    DATA gt_ctry TYPE tt_ctry .
    DATA gt_material TYPE tt_material .
    DATA gt_mch1 TYPE tt_mch1 .
    DATA gt_serial TYPE tt_serial .
    DATA gt_text TYPE truxs_t_text_data .
    DATA it_lips TYPE tt_lips .
    CLASS-DATA lt_characteristics TYPE zuts_tt_characteristic .
    CLASS-DATA lt_ce_mark TYPE zuts_tt_spec_characteristics .
    CONSTANTS c_fname_sales TYPE string VALUE 'Sales_Notif-' ##NO_TEXT.
    CONSTANTS c_fname_import TYPE string VALUE 'Import_Notif-' ##NO_TEXT.
    CONSTANTS c_csv TYPE string VALUE '.csv' ##NO_TEXT.
    CONSTANTS c_char_inf TYPE string VALUE 'ZRG_REGULATORY_INF' ##NO_TEXT.
    CONSTANTS c_char_mark TYPE string VALUE 'ZS_REGULATIONS_CE_MARK ' ##NO_TEXT.
    CONSTANTS c_char_code TYPE string VALUE 'ZSD_CODE2' ##NO_TEXT.
    CONSTANTS c_uts_foc TYPE string VALUE 'ZSD_UTS_FOC_DELITEM' ##NO_TEXT.  " İtem catagory kontrolü için eklenmiş
    "ZEXP,TANN,ZWAR gelmiş ve , ile ayırıp itaba atmış

    METHODS add_header_data_ztro .
    METHODS add_header_data_ztri .
    METHODS convert_to_csv_format
      IMPORTING
        !iv_output     TYPE STANDARD TABLE
      RETURNING
        VALUE(rv_conv) TYPE truxs_t_text_data .
    CLASS-METHODS check_material
      IMPORTING
        !iv_delivery              TYPE vbeln_vl
      RETURNING
        VALUE(rv_renew_materials) TYPE flagd .
ENDCLASS.



CLASS ZUTS_CL_NOTIFICATION IMPLEMENTATION.


  METHOD add_header_data_ztri.

    gt_output = VALUE #( BASE gt_output
                         ( ean11      = 'UNO'(uno)
                           charg      = 'LNO'(lno)
                           sernr      = 'SNO'(sno)
                           hsdat      = 'URT'(urt)
                           vfdat      = 'SKT'(skt)
                           wadat_ist  = 'ITT'(itt)
                           lgmng      = 'ADT'(adt)
                           matnr      = 'UDI'(udi)
                           ctryname   = 'IEU'(ieu)
                           ctryorigin = 'MEU'(meu)
                           vbeln      = 'GBN'(gbn)
                           meins      = TEXT-009
                           maktx      = TEXT-001
                           stcd1      = TEXT-014
                           lifnr      = TEXT-015 )
                       ).
  ENDMETHOD.


  METHOD add_header_data_ztro.

    gt_outsales = VALUE #( BASE gt_outsales
                           ( ean11     = 'UNO'(uno)
                             charg     = 'LNO'(lno)
                             sernr     = 'SNO'(sno)
                             lgmng     = 'ADT'(adt)
                             zuts_code = 'KUN'(kun)
                             zben      = 'BEN'(ben)
                             vbeln     = TEXT-013
                             wadat_ist = TEXT-007
                             matnr     = TEXT-002
                             meins     = TEXT-009
                             maktx     = TEXT-001 )
                         ).

  ENDMETHOD.


  METHOD build_data_output_ztri.

    "add_header_data_ztri( ).

    LOOP AT gt_lips ASSIGNING FIELD-SYMBOL(<fs_lips>).

      gs_output-maktx     = VALUE #( gt_material[ matnr = <fs_lips>-matnr ]-maktx OPTIONAL ).
      gs_output-matnr     = <fs_lips>-matnr.
      gs_output-wadat_ist = gs_likp-wadat_ist.

      gs_output-charg = <fs_lips>-charg.
      gs_output-lgmng = <fs_lips>-lgmng.
      gs_output-meins = <fs_lips>-meins.

      gs_output-hsdat = <fs_lips>-hsdat.
      gs_output-vfdat = COND #( WHEN <fs_lips>-vfdat IS INITIAL THEN '' ELSE <fs_lips>-vfdat ).

      gs_output-ean11      = VALUE #( gt_material[ matnr = <fs_lips>-matnr ]-ean11 OPTIONAL ).
      gs_output-ctryname   = VALUE #( gt_ctry[ lifnr = gs_likp-lifnr ]-landx50 OPTIONAL ).
      gs_output-ctryorigin = VALUE #( gt_mch1[ matnr = <fs_lips>-matnr charg = <fs_lips>-charg ]-landx50 OPTIONAL ).

      gs_output-vbeln = <fs_lips>-vbeln.
      gs_output-stcd1 = gv_stcd1.
      gs_output-lifnr = gs_likp-lifnr.

      IF line_exists( gt_serial[ posnr = <fs_lips>-posnr ] ).
        gs_output-lgmng = CONV lgmng( '1' ). "qty should always be 1 on serialized item
        LOOP AT gt_serial ASSIGNING FIELD-SYMBOL(<fs_serial>) WHERE posnr = <fs_lips>-posnr.

          gs_output-sernr = <fs_serial>-sernr.

          APPEND gs_output TO gt_output.

        ENDLOOP.

      ELSE.

        APPEND gs_output TO gt_output.
      ENDIF.

      CLEAR: gs_output.

    ENDLOOP.

  ENDMETHOD.


  METHOD build_data_output_ztro.

    "add_header_data_ztro( ).

*    TRY.
*        zcl_global_variables=>get_parameter_table(
*          EXPORTING iv_name  = c_uts_foc
*          IMPORTING et_param = lt_allowed_pstyv ).
*        data(lt_allowed_pstyv) = VALUE #( pstyv = 'TANN' ).
*        LOOP AT lt_allowed_pstyv ASSIGNING FIELD-SYMBOL(<fs_pstyv>).
*          CONDENSE <fs_pstyv>.
*        ENDLOOP.

*      CATCH zcx_global.
*    ENDTRY.
    ls_allowed_pstyv-pstyv = 'TANN'.
    APPEND ls_allowed_pstyv to lt_allowed_pstyv.
    SELECT SINGLE a~atwrt
      INTO @DATA(lv_stceg)
      FROM ausp AS a
      JOIN cabn AS b
        ON b~atinn = a~atinn
      WHERE b~atnam = @c_char_code
        AND a~objek = @gs_likp-kunag.

    IF lv_stceg IS INITIAL.
      SELECT SINGLE stceg
        INTO lv_stceg
        FROM kna1
        WHERE kunnr = gs_likp-kunag.
    ENDIF.

    LOOP AT gt_lips ASSIGNING FIELD-SYMBOL(<fs_lips>).

      gs_outsales-ean11 = VALUE #( gt_material[ matnr = <fs_lips>-matnr ]-ean11 OPTIONAL ).
      gs_outsales-charg = <fs_lips>-charg.

      gs_outsales-lgmng = <fs_lips>-lgmng.

      lv_pstyv = COND #( WHEN <fs_lips>-uecha IS NOT INITIAL
                          THEN VALUE #( it_lips[ posnr = <fs_lips>-uecha ]-pstyv OPTIONAL ) ).

      DATA(x_pstyv) = VALUE #( lt_allowed_pstyv[ pstyv = lv_pstyv ]-pstyv OPTIONAL ).

      gs_outsales-zben = COND #( WHEN x_pstyv IS NOT INITIAL THEN 'YES' ELSE 'NO' ).

      gs_outsales-zuts_code = lv_stceg.

      gs_outsales-vbeln     = <fs_lips>-vbeln.
      gs_outsales-wadat_ist = gs_likp-wadat_ist.
      gs_outsales-matnr     = <fs_lips>-matnr.
      gs_outsales-meins     = <fs_lips>-meins.
      gs_outsales-maktx     = VALUE #( gt_material[ matnr = <fs_lips>-matnr ]-maktx OPTIONAL ).

      IF line_exists( gt_serial[ posnr = <fs_lips>-posnr ] ).
        gs_outsales-lgmng = CONV lgmng( '1' ). "qty should always be 1 on serialized item
        LOOP AT gt_serial ASSIGNING FIELD-SYMBOL(<fs_serial>) WHERE posnr = <fs_lips>-posnr.

          gs_outsales-sernr = <fs_serial>-sernr.

          APPEND gs_outsales TO gt_outsales.

        ENDLOOP.

      ELSE.

        APPEND gs_outsales TO gt_outsales.
      ENDIF.

      CLEAR: gs_outsales, lv_pstyv.

    ENDLOOP.
  ENDMETHOD.


  METHOD check_material.
*    CLEAR: rv_renew_materials, lt_characteristics, lt_ce_mark.
*
*    IF iv_delivery IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    "Get all the Delivery Items for the Delivery
**    DATA(lt_dlvry_mats) = zcl_sms_prep_and_retrieve_spec=>get_delivery_items(
**           iv_delivery = iv_delivery ).
*
*    CLEAR: rt_materials.
*
**-- Get all the Delivery Items for the Delivery
*    SELECT matnr
*      FROM lips
*      INTO TABLE @DATA(lt_dlvry_mats)
*     WHERE vbeln = @iv_delivery.
*
*    IF sy-subrc = 0.
*      SORT lt_lips BY matnr.
*      DELETE ADJACENT DUPLICATES FROM lt_dlvry_mats COMPARING ALL FIELDS.
**      rt_materials[] = lt_lips[].
*    ENDIF.
*
*    IF lt_dlvry_mats[] IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    "Prepare the Materials and the Vendors
*    DATA(lt_material_vendor) = zcl_sms_prep_and_retrieve_spec=>prepare_material_list(
*         it_delvry_materials = lt_dlvry_mats ).
*
*    "Required Characteristics
*
**-- Loading the Characteristics required from Spec Management
*    APPEND INITIAL LINE TO lt_characteristics ASSIGNING FIELD-SYMBOL(<ls_chars0>).
*    <ls_chars0>-atnam = c_char_inf.
*
*    APPEND INITIAL LINE TO lt_characteristics ASSIGNING FIELD-SYMBOL(<ls_chars1>).
*    <ls_chars1>-atnam = c_char_mark.
*
*    "Returns all the Spec characteristics requested per Material
*    DATA(lt_spec_chars) = zcl_sms_get_material_chars=>main(
*     it_matnr_lifnr     = lt_material_vendor
*     it_characteristics  = lt_characteristics ).
*
*    "Are there any CE marked entries
*    lt_ce_mark = lt_spec_chars[].
*    DELETE lt_ce_mark WHERE atnam NE c_char_inf AND
*                            atnam NE c_char_mark.
*    DELETE lt_ce_mark WHERE atwrt NE 'YES'.
*
*    IF lt_ce_mark[] IS NOT INITIAL.
*      "There are CE marked entries
*      rv_renew_materials = abap_true.
*    ENDIF.
  ENDMETHOD.


  METHOD check_output_routine.
* Check Qty is GT 0 for alteast one line and PGI is done
    FIELD-SYMBOLS: <lt_lips_t> TYPE tab_lipsvb,
                   <ls_likp>   TYPE likp.
    DATA: ls_lips     TYPE lipsvb,
          lv_rejected TYPE flag VALUE 'X'.

    CLEAR rv_subrc.

    "Step 1 - Check Goods Movement staus is complete
    IF iv_wbstk NE 'C'.
      rv_subrc = 4.
      EXIT.
    ELSE.
      "Step 2 -  Check GR Qty is not equal to zero for atleast one line.
      ASSIGN ('(SAPMV50A)xlips[]') TO <lt_lips_t>.
      IF sy-subrc NE 0.
        rv_subrc = sy-subrc.
        RETURN.
      ENDIF.

      ASSIGN ('(SAPMV50A)likp') TO <ls_likp>.
      IF sy-subrc NE 0.
        rv_subrc = sy-subrc.
        RETURN.
      ENDIF.

      LOOP AT <lt_lips_t> INTO ls_lips.
        IF NOT ls_lips-lfimg IS INITIAL.
          "one line qty is GT 0 found
          CLEAR lv_rejected.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF NOT lv_rejected IS INITIAL.
        rv_subrc = 4.  "Rejected - means output need to be stoped immediately
      ELSE.
        rv_subrc = 0.
      ENDIF.

*********checking of material remarks
      DATA(lv_materials) = check_material(
                   iv_delivery = <ls_likp>-vbeln ).

      sy-subrc = 4.

      IF lv_materials = abap_true.

        "If the Language in NAST is the same as that expected of the
        "Customer, the Output can go ahead
*        IF lv_nast_spras = lv_spras.
        sy-subrc = 0.
*        ELSE.
*          sy-subrc = 4.
*        ENDIF.
      ELSE.
        sy-subrc = 4.
      ENDIF.
*********checking of material remarks
    ENDIF.
  ENDMETHOD.


  METHOD class_constructor.
  ENDMETHOD.


  METHOD constructor.
    SET LANGUAGE iv_langu.
  ENDMETHOD.


  METHOD convert_to_csv_format.

    CALL FUNCTION 'SAP_CONVERT_TO_TEX_FORMAT'
      EXPORTING
        i_field_seperator    = ';'
      TABLES
        i_tab_sap_data       = iv_output
      CHANGING
        i_tab_converted_data = rv_conv
      EXCEPTIONS
        conversion_failed    = 1
        OTHERS               = 2.
    IF sy-subrc <> 0.
      return_message( ).
    ENDIF.

  ENDMETHOD.


  METHOD download_data.
*
*    SELECT SINGLE file_path
*      FROM zsd_forms_dnload
*      INTO gv_fpath
*      WHERE output_type = iv_kschl.

*    IF gv_fpath IS NOT INITIAL.
*
*      gv_fpath = SWITCH #( iv_kschl
*                           WHEN 'ZTRI'
*                            THEN |{ gv_fpath }{ c_fname_import }{ gs_likp-vbeln }{ c_csv }|
*                           WHEN 'ZTRO'
*                             THEN |{ gv_fpath }{ c_fname_sales }{ gs_likp-vbeln }{ c_csv }| ).
*
*      gt_text = SWITCH #( iv_kschl
*                           WHEN 'ZTRI'
*                            THEN convert_to_csv_format( gt_output )
*                           WHEN 'ZTRO'
*                             THEN convert_to_csv_format( gt_outsales ) ).
*
*      OPEN DATASET gv_fpath FOR OUTPUT IN TEXT MODE ENCODING UTF-8.
*
*      IF sy-subrc EQ 0.
*
*        LOOP AT gt_text ASSIGNING FIELD-SYMBOL(<fs_l_wa>).
*          TRANSFER <fs_l_wa> TO gv_fpath.
*        ENDLOOP.
*        CLOSE DATASET gv_fpath.
*
*      ELSE.
*        return_message( ).
*      ENDIF.
*
*    ENDIF.

  ENDMETHOD.


  METHOD download_data_per_line.
*
*    SELECT SINGLE file_path
*      FROM zsd_forms_dnload
*      INTO gv_fpath
*      WHERE output_type = iv_kschl.
*
*    IF gv_fpath IS NOT INITIAL.
*
*      gt_text = SWITCH #( iv_kschl
*                           WHEN 'ZTRI'
*                            THEN convert_to_csv_format( gt_output )
*                           WHEN 'ZTRO'
*                             THEN convert_to_csv_format( gt_outsales ) ).
*
*      LOOP AT gt_text ASSIGNING FIELD-SYMBOL(<fs_l_wa>).
*
*        DATA(lv_path) = SWITCH #( iv_kschl
*                          WHEN 'ZTRI'
*                           THEN |{ gv_fpath }{ c_fname_import }{ gs_likp-vbeln }_{ sy-tabix }{ c_csv }|
*                          WHEN 'ZTRO'
*                            THEN |{ gv_fpath }{ c_fname_sales }{ gs_likp-vbeln }_{ sy-tabix }{ c_csv }| ).
*
*        OPEN DATASET lv_path FOR OUTPUT IN TEXT MODE ENCODING UTF-8.
*
*        IF sy-subrc EQ 0.
*
*          TRANSFER <fs_l_wa> TO lv_path.
*
*          CLOSE DATASET lv_path.
*
*        ELSE.
*          return_message( ).
*        ENDIF.
*        CLEAR: lv_path.
*      ENDLOOP.
*
*    ENDIF.

  ENDMETHOD.


  METHOD get_delivery_data.

    DATA(lv_materials) = check_material(
                  iv_delivery = iv_vbeln ).

    IF lv_materials IS INITIAL.
      rv_retcode = 4.
      EXIT.
    ENDIF.

    SELECT SINGLE * FROM likp
      INTO gs_likp
      WHERE vbeln = iv_vbeln.

    SELECT * FROM lips
      INTO TABLE gt_lips
      WHERE vbeln = iv_vbeln.

    IF gt_lips IS NOT INITIAL.

      it_lips[] = gt_lips[].

      LOOP AT it_lips ASSIGNING FIELD-SYMBOL(<fs_lips>).

        IF line_exists( lt_ce_mark[ matnr = <fs_lips>-matnr ] ).
          IF <fs_lips>-uecha IS NOT INITIAL. "Do not include main item if it has batch split items;
            DELETE gt_lips WHERE posnr = <fs_lips>-uecha.
          ENDIF.
        ELSE. "Do not include items not marked as YES in CE_REMARK
          DELETE gt_lips WHERE matnr = <fs_lips>-matnr.
        ENDIF.

      ENDLOOP.

      IF gt_lips IS NOT INITIAL.
        SELECT a~posnr b~obknr b~sernr b~matnr
           INTO CORRESPONDING FIELDS OF TABLE gt_serial
           FROM ser01 AS a
           JOIN objk AS b
             ON b~obknr = a~obknr
           FOR ALL ENTRIES IN gt_lips
           WHERE a~lief_nr = gt_lips-vbeln.

        SELECT SINGLE stcd1
          FROM lfa1
          INTO gv_stcd1
          WHERE lifnr = gs_likp-lifnr.

        SELECT a~matnr a~ean11 b~maktx
          INTO CORRESPONDING FIELDS OF TABLE gt_material
          FROM mara AS a
          JOIN makt AS b
            ON b~matnr = a~matnr
           AND b~spras = 'E'
          FOR ALL ENTRIES IN gt_lips
          WHERE a~matnr = gt_lips-matnr.

        SELECT a~matnr a~charg a~herkl b~landx50
          INTO CORRESPONDING FIELDS OF TABLE gt_mch1
          FROM mch1 AS a
          JOIN t005t AS b
            ON b~land1 = a~herkl
          FOR ALL ENTRIES IN gt_lips
          WHERE matnr = gt_lips-matnr
            AND charg = gt_lips-charg
            AND b~spras = 'E'.

        SELECT a~lifnr a~land1 b~landx50
          INTO CORRESPONDING FIELDS OF TABLE gt_ctry
          FROM lfa1 AS a
          JOIN t005t AS b
            ON b~land1 = a~land1
          WHERE a~lifnr = gs_likp-lifnr
            AND b~spras = 'E'.

      ENDIF.
    ENDIF.

    rv_retcode = COND #( WHEN gt_lips IS NOT INITIAL THEN 0 ELSE 4 ).

  ENDMETHOD.


  METHOD return_message.

    CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
      EXPORTING
        msg_arbgb = sy-msgid
        msg_nr    = sy-msgno
        msg_ty    = sy-msgty
        msg_v1    = sy-msgv1
        msg_v2    = sy-msgv2
      EXCEPTIONS
        OTHERS    = 0.

  ENDMETHOD.
ENDCLASS.
