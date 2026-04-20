*&---------------------------------------------------------------------*
*& Report  ZUTS_P001
*&---------------------------------------------------------------------*
*& UTS Web Servis Test Programi
*&
*& ZUTS_CL001 sinifini tuketen, PDF'ten alinan ornek (dummy) JSON
*& verileriyle 6 UTS servisini test eden programdir.
*&
*& Sadece TEST ortami desteklidir.
*&
*& Mimari (Clean-core + OOP, include bazli):
*&   ZUTS_P001         : Ana program (REPORT + includes + events)
*&   ZUTS_P001_SEL     : Secim ekrani
*&   ZUTS_P001_SRV     : lcl_dummy_data + lcl_service_runner
*&   ZUTS_P001_ALV     : lcl_alv_view
*&   ZUTS_P001_APP     : lcl_app (controller)
*&---------------------------------------------------------------------*
REPORT zuts_p001.

INCLUDE <icon>.

INCLUDE zuts_p001_sel.   " Secim ekrani
INCLUDE zuts_p001_srv.   " Servis runner + dummy data
INCLUDE zuts_p001_alv.   " ALV gosterim
INCLUDE zuts_p001_app.   " Uygulama controller

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN OUTPUT
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
