--create or replace PROCEDURE        CUP_SP_HOMOLOGA_FECHA_TEST
--IS
--query para verificar el proceso en produccion del paquete PKG_CUP_SP_HOMOLOGA_FECHA
--set serveroutput on size 1000000;
DECLARE
    CURSOR c_empleados IS
        SELECT ID_EMISION_SF
          , SF.ID_FORMACION
          , ED.ID_EVALUACION_DESEMPENIO
          , SF.ID_COMPETENCIA_BASICA
          , PER.CUIP
          , SF.ID_PERSONA
          , SF.EMISION_CUP
          , SF.ESTATUS_FORMATO_SF
          , SF.ESTATUS_CUP
          , SF.FECHA_EMISION_SF
          , SF.ID_ECCC
          , EV."Fecha_Evaluacion" FECHA_EVALUACION_ECCC
          , EV."Fecha_Evaluacion" + 1095 FECHA_VENCIMIENTO_ECCC --1095 DIAS = 3 AÑOS
          , EV."Id_Tipo_Evaluacion" ID_TIPO_EVALUACION
          , EV."borrado" BORRADO
          , EV."Id_Resultado_Integral" ID_RESULTADO_INTEGRAL
          , FI.FECHA_CONCLUSION FECHA_CONCLUSION_FI
          , FI.ESTATUS_CURSO ESTATUS_CURSO_FI
          , CB.FECHA_EVALUACION FECHA_EVALUACION_CB
          , CB.ESTATUS_REGISTRO ESTATUS_COMPETENCIA
          , ED.FECHA_EVALUACION FECHA_EVALUACION_DESEMPENIO
          , SF.FECHA_EMISION_CUP
          , ED.ESTATUS_EVALUACION ESTATUS_DESEMPENIO
          , (SELECT count(1) FROM cup_bit_homologa_fechas BCC WHERE bcc.id_emision_sf = sf.id_emision_sf) CUMPLE
          , SYSDATE FECHA_COMPARA
         FROM emision_sf sf
         INNER JOIN persona@PERSONAL_CUP per on per.ID_PERSONA = SF.ID_PERSONA
         LEFT JOIN formacion_inicial fi on FI.ID_FORMACION = SF.id_formacion
         LEFT JOIN competencia_basica CB on CB.ID_COMPETENCIA_BASICA = SF.ID_COMPETENCIA_BASICA
         LEFT JOIN evaluacion_desempenio ED on ED.ID_EVALUACION_DESEMPENIO = sf.ID_EVALUACION_DESEMPENIO
         INNER JOIN evaluacion@DB_ECCC EV ON EV."Id_Evaluacion" = SF.ID_ECCC AND EV."Id_Tipo_Evaluacion" IN (1,2)
         WHERE sf.EMISION_CUP IS NOT NULL
         AND sf.ESTATUS_CUP in (0,1)
         AND SF.ID_EMISION_SF IN (SELECT max(ESF.id_emision_sf)
									  FROM emision_sf ESF
									 WHERE ESF.id_persona = sf.id_persona
									   AND ESF.emision_cup is not null)
         AND SF.id_persona NOT IN (SELECT ESF1.id_persona 
                                    FROM CUP_BIT_HOMOLOGA_FECHAS BHFC
                                    INNER JOIN emision_sf ESF1 on ESF1.ID_EMISION_SF = BHFC.ID_EMISION_SF
                                    WHERE ESF1.id_persona = ESF1.id_persona)
         ORDER BY sf.id_persona, sf.id_emision_sf DESC;
		 
    TYPE EmpType IS TABLE OF c_empleados%ROWTYPE;
    emp_tab EmpType;
    VNBANDERA NUMBER(1) := 0;
	
FUNCTION FN_CALCULA_MESESDIAS(vd_fecha date) RETURN NUMBER
            IS
        VANIOS NUMBER(5,3) := 0;
        VMESES NUMBER(5,3) := 0;
        VDIAS  NUMBER(5,3) := 0;
        BEGIN
                   VANIOS := TRUNC ( MONTHS_BETWEEN ( SYSDATE, TRUNC( vd_fecha )) / 12 );
                   VMESES := TRUNC(MOD ( FLOOR ( MONTHS_BETWEEN ( SYSDATE, TRUNC ( vd_fecha) ) ), 12 ));
                   VDIAS := TRUNC(SYSDATE - add_months(vd_fecha, trunc(months_between(SYSDATE, TRUNC ( vd_fecha )))));
                   RETURN (VANIOS * 12) + VMESES + (VDIAS / 100);
            EXCEPTION
                WHEN OTHERS   THEN
                    RETURN 0;
        END FN_CALCULA_MESESDIAS;
		
        FUNCTION FN_ACTUALIZA_CUP(VNIDEMISIONSF INT) RETURN NUMBER
        IS
        BEGIN
          /*  UPDATE EMISION_SF
                 SET ESTATUS_CUP = 1, ESTATUS_FORMATO_SF = 0
             WHERE ID_EMISION_SF = VNIDEMISIONSF;*/
			 DBMS_OUTPUT.PUT_LINE('Actualiza FN_ACTUALIZA_CUP...' || TO_CHAR(VPIDEMISION));
                RETURN 1;
        EXCEPTION
            WHEN NO_DATA_FOUND  THEN
                RETURN 0;
            WHEN OTHERS   THEN
                RETURN 0;
        END FN_ACTUALIZA_CUP;
		
        PROCEDURE PR_ACTUALIZA_BITACORA(VPIDEMISION NUMBER, VFECCB DATE, VFECED DATE, VFECECC DATE)
        IS
        BEGIN
                --INSERT INTO CUP_BIT_HOMOLOGA_FECHAS (ID_EMISION_SF, FECHA_EVALUACION_CB, FECHA_EVALUACION_ED, FECHA_ECCC)
                --VALUES (VPIDEMISION, VFECCB, VFECED,VFECECC );
                 DBMS_OUTPUT.PUT_LINE('Se bitacoriza id_emision...:' || TO_CHAR(VPIDEMISION));
            EXCEPTION
            WHEN OTHERS   THEN
                DBMS_OUTPUT.PUT_LINE('Problema en el Procedimiento PR_ACTUALIZA_BITACORA...' || TO_CHAR(VPIDEMISION));
        END PR_ACTUALIZA_BITACORA;
		
BEGIN
    OPEN c_empleados;
    FETCH c_empleados BULK COLLECT INTO emp_tab;
    CLOSE c_empleados;
	
    FOR i IN 1..emp_tab.COUNT LOOP
        --DBMS_OUTPUT.PUT_LINE('Empleado ' || emp_tab(i).ID_EMISION_SF || ': CUIP..: ' || emp_tab(i).CUIP);
        IF FN_CALCULA_MESESDIAS(emp_tab(i).FECHA_EVALUACION_ECCC) < 36.0
            THEN
            BEGIN
            IF emp_tab(i).ID_COMPETENCIA_BASICA != 0 THEN --¿Existe registro de la evaluación de Competencias Basicas en el CUP ?
                --La fecha de la Competencia Basica es 5 anios <= a la fecha actual?
                IF FN_CALCULA_MESESDIAS(emp_tab(i).FECHA_EVALUACION_CB) < 60.0
                  THEN
                    --¿La fecha de la Evaluación de Control de Confianza > a  la Fecha de la Evaluación de Competencias Basicas?
                    IF emp_tab(i).FECHA_EVALUACION_ECCC > emp_tab(i).FECHA_EVALUACION_CB  THEN
                        --¿La Fecha de  Evaluación de Desempenio (Academico/Laboral) es 5 anios menor a la fecha actual?
                        IF FN_CALCULA_MESESDIAS(emp_tab(i).FECHA_EVALUACION_DESEMPENIO) < 60.0
                          THEN
                            --¿La fecha de la Evaluación de Control de Confianza > a la Fecha de la Evaluación de Desempenio (Academico/Laboral)?
                            IF emp_tab(i).FECHA_EVALUACION_ECCC > emp_tab(i).FECHA_EVALUACION_DESEMPENIO  THEN
                                BEGIN
                                    --Actualiza el Estatus del CUP
                                    IF emp_tab(i).ESTATUS_CUP = 0 THEN
                                        VNBANDERA := FN_ACTUALIZA_CUP(emp_tab(i).ID_EMISION_SF);
                                    END IF;--(1 ACTUALIZA CUP)
                                    --Actualiza Bitacora
                                    PR_ACTUALIZA_BITACORA(emp_tab(i).ID_EMISION_SF, emp_tab(i).FECHA_EVALUACION_CB, emp_tab(i).FECHA_EVALUACION_DESEMPENIO
                                   , emp_tab(i).FECHA_EVALUACION_ECCC);
                                END;--(2 ACT BITACORA)
                            END IF;--(3 ECCC MAYOR ECC)
                        END IF;--(4 ED)
                    END IF;--(5 ECC MAYOR CB)
                END IF;--(6 MAYO A 60.0)
            ELSE
                --DBMS_OUTPUT.PUT_LINE('Registro ID_EMISION_SF...' || TO_CHAR(emp_tab(i).ID_EMISION_SF) || '--> Meses FI..:'|| to_char(FN_CALCULA_MESESDIAS(emp_tab(i).FECHA_CONCLUSION_FI)));
                 IF FN_CALCULA_MESESDIAS(emp_tab(i).FECHA_CONCLUSION_FI) < 36.0
                 THEN
                        --¿La fecha de la Evaluación de Control de Confianza > a la Fecha de la Evaluación de DesempeÃ±o (AcadÃ©mico/Laboral)?
                        IF emp_tab(i).FECHA_EVALUACION_ECCC > emp_tab(i).FECHA_CONCLUSION_FI THEN
                                --¿La Fecha de  Evaluación de Desempenio (AcadÃ©mico/Laboral) es 5 anios menor a la fecha actual?
                                IF FN_CALCULA_MESESDIAS(emp_tab(i).FECHA_EVALUACION_DESEMPENIO) < 60.0
                                 THEN
                                    --¿La fecha de la Evaluación de Control de Confianza > a la Fecha de la Evaluación de Desempenio (Academico/Laboral)?
                                    IF emp_tab(i).FECHA_EVALUACION_ECCC > emp_tab(i).FECHA_EVALUACION_DESEMPENIO THEN
                                        BEGIN
                                            --Actualiza el Estatus del CUP
                                            IF emp_tab(i).ESTATUS_CUP = 0 THEN
                                                VNBANDERA := FN_ACTUALIZA_CUP(emp_tab(i).ID_EMISION_SF);
                                            END IF;
                                            --Actualiza Bitacora
                                            PR_ACTUALIZA_BITACORA(emp_tab(i).ID_EMISION_SF, emp_tab(i).FECHA_EVALUACION_CB, emp_tab(i).FECHA_EVALUACION_DESEMPENIO, emp_tab(i).FECHA_EVALUACION_ECCC);
                                        END;
                                    END IF;
                            END IF;
                    END IF;
                END IF;
            END IF;
        END;
        END IF; --(1)
    COMMIT;
    END LOOP;
	
    DBMS_OUTPUT.PUT_LINE('TERMINE...');
	
    EXCEPTION
        WHEN OTHERS   THEN
            DBMS_OUTPUT.PUT_LINE('Problema en el Procedimiento CUP_SP_HOMOLOGA_FECHA...' );
END;