*&---------------------------------------------------------------------*
*&  Include           ZUTS_P001_SEL
*&---------------------------------------------------------------------*
*& Secim ekrani: servis radyo butonlari + baglanti bilgileri
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
