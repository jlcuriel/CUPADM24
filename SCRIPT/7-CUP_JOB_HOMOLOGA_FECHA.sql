-----------------------------------------------------------------------------
-- Creación: Marzo 24
-- Autor: JLCR
-- Descripción: JOB, homologa fecha de evaluacion_desempeño y competencia
-- Modificación: 
-----------------------------------------------------------------------------

DECLARE
  X NUMBER;
BEGIN
  SYS.DBMS_JOB.SUBMIT
  ( job       => X 
   ,what      => 'CUPADM.PKG_CUP_SP_HOMOLOGA_FECHA.CUP_SP_HOMOLOGA_FECHA;'
   ,next_date => to_date('01/07/2023 01:00:00','dd/mm/yyyy hh24:mi:ss')
   ,interval  => 'TRUNC(SYSDATE+1)+3/24'
   ,no_parse  => FALSE
  );
  SYS.DBMS_OUTPUT.PUT_LINE('Job Número is: ' || to_char(x));
COMMIT;
END;
/