-----------------------------------------------------------------------------
-- Creación: Marzo 24
-- Autor: JLCR
-- Descripción: JOB, Ejecuta el calculo para actualizar el estatus_cup y estatus_formato_sf de acuerdo a 
-- las vigencias por sus evaluaciones
-- Modificación: 
-----------------------------------------------------------------------------

DECLARE
  X NUMBER;
BEGIN
  SYS.DBMS_JOB.SUBMIT
  ( job       => X 
   ,what      => 'CUPADM.PKG_CUP_SP_CALCULO_CUP.CUP_SP_CALCULO_CUP;'
   ,next_date => to_date('01/07/2023 01:00:00','dd/mm/yyyy hh24:mi:ss')
   ,interval  => 'TRUNC(SYSDATE+1)+3/24'
   ,no_parse  => FALSE
  );
  SYS.DBMS_OUTPUT.PUT_LINE('Job ´Número: ' || to_char(x));
COMMIT;
END;
/