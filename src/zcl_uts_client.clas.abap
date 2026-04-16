CLASS zcl_uts_client DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING iv_dest TYPE rfcdest.

    METHODS verme_bildirimi
      IMPORTING iv_token    TYPE string
                iv_json     TYPE string
      EXPORTING ev_response TYPE string
                ev_status   TYPE i.

    METHODS alma_bildirimi
      IMPORTING iv_token    TYPE string
                iv_json     TYPE string
      EXPORTING ev_response TYPE string
                ev_status   TYPE i.

  PRIVATE SECTION.

    DATA mo_http TYPE REF TO if_http_client.

ENDCLASS.



CLASS ZCL_UTS_CLIENT IMPLEMENTATION.


  METHOD constructor.

    cl_http_client=>create_by_destination(
      EXPORTING
        destination = iv_dest
      IMPORTING
        client      = mo_http
      EXCEPTIONS
        OTHERS      = 1 ).

    IF sy-subrc <> 0.
      MESSAGE 'HTTP client olusturulamadi' TYPE 'E'.
    ENDIF.

  ENDMETHOD.


  METHOD verme_bildirimi.

    DATA ls_log TYPE zuts_log.

    mo_http->request->set_method( if_http_request=>co_request_method_post ).

    cl_http_utility=>set_request_uri(
      request = mo_http->request
      uri     = '/UTS/uh/rest/bildirim/verme/ekle/essizKimlik' ).

    mo_http->request->set_header_field(
      name  = 'Content-Type'
      value = 'application/json' ).

    mo_http->request->set_header_field(
      name  = 'Accept'
      value = 'application/json' ).

    mo_http->request->set_header_field(
      name  = 'Authorization'
      value = |Bearer { iv_token }| ).

    mo_http->request->set_cdata( iv_json ).

    mo_http->send( EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      ev_status   = 0.
      ev_response = 'HTTP gonderim hatasi'.
      RETURN.
    ENDIF.

    mo_http->receive( EXCEPTIONS OTHERS = 1 ).

    ev_response = mo_http->response->get_cdata( ).
    mo_http->response->get_status( IMPORTING code = ev_status ).


    ls_log-logid = |{ sy-datum }{ sy-uzeit }{ sy-uname }{ sy-uzeit }|.


    ls_log-username    = sy-uname.
    GET TIME STAMP FIELD ls_log-called_at.
    ls_log-endpoint    = '/UTS/uh/rest/bildirim/verme/ekle/essizKimlik'.
    ls_log-request     = iv_json.
    ls_log-response    = ev_response.
    ls_log-http_status = ev_status.

    INSERT zuts_log FROM ls_log.
    COMMIT WORK.

  ENDMETHOD.


  METHOD alma_bildirimi.

    DATA ls_log TYPE zuts_log.

    mo_http->request->set_method( if_http_request=>co_request_method_post ).

    cl_http_utility=>set_request_uri(
      request = mo_http->request
      uri     = '/UTS/uh/rest/bildirim/alma/ekle' ).

    mo_http->request->set_header_field(
      name  = 'Content-Type'
      value = 'application/json' ).

    mo_http->request->set_header_field(
      name  = 'Accept'
      value = 'application/json' ).

    mo_http->request->set_header_field(
      name  = 'Authorization'
      value = |Bearer { iv_token }| ).

    mo_http->request->set_cdata( iv_json ).

    mo_http->send( EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      ev_status   = 0.
      ev_response = 'HTTP gonderim hatasi'.
      RETURN.
    ENDIF.

    mo_http->receive( EXCEPTIONS OTHERS = 1 ).

    ev_response = mo_http->response->get_cdata( ).
    mo_http->response->get_status( IMPORTING code = ev_status ).

    ls_log-logid = |{ sy-datum }{ sy-uzeit }{ sy-uname }{ sy-uzeit }|.
    ls_log-username    = sy-uname.
    GET TIME STAMP FIELD ls_log-called_at.
    ls_log-endpoint    = '/UTS/uh/rest/bildirim/alma/ekle'.
    ls_log-request     = iv_json.
    ls_log-response    = ev_response.
    ls_log-http_status = ev_status.

    INSERT zuts_log FROM ls_log.
    COMMIT WORK.

  ENDMETHOD.
ENDCLASS.
