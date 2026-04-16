REPORT zuts_menu_start.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS:
  p_verme  RADIOBUTTON GROUP g1 DEFAULT 'X',
  p_alma   RADIOBUTTON GROUP g1,
  p_ithal  RADIOBUTTON GROUP g1,
  p_ihrac  RADIOBUTTON GROUP g1,
  p_iptal  RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  IF p_verme = 'X'.
    CALL TRANSACTION 'ZUTS01'.
  ELSEIF p_alma = 'X'.
    CALL TRANSACTION 'ZUTS02'.
  ELSEIF p_ithal = 'X'.
    MESSAGE 'Ithalat bildirimi henuz hazir degil' TYPE 'I'.
  ELSEIF p_ihrac = 'X'.
    MESSAGE 'Ihracat bildirimi henuz hazir degil' TYPE 'I'.
  ELSEIF p_iptal = 'X'.
    MESSAGE 'Iptal bildirimi henuz hazir degil' TYPE 'I'.
  ENDIF.
