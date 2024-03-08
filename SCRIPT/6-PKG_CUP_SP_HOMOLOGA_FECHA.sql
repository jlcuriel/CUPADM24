CREATE OR REPLACE PACKAGE CUPADM.PKG_CUP_SP_HOMOLOGA_FECHA IS
/******************************************************************************
-----------------------------------------------------------------------------
-- Creación: Enero 24
-- Autor: JLCR
-- Descripción: ACTUALIZA, ESTATUS_CUP Y ESTATUS_FORMATO_SF DE ACURDO A LAS VIGENCIAS DE SUS EVALUACIONES
-- Modificación: Se Actualizo la logica conforme el diagram enviado por Arturo Dúran el Día 05/04/2023
--              documento de WORD CC_RNPSP_CUP_HomEvalu_V3.20.0 - V2.docx
-- Modificacion: 12 JULIO 23, se adiciono la funcion de FN_CALCULA_FECHAS, por modularidad
-- Modificación: 11 Diciembre 2023, conforme observaciones enviadas por El área de Analisis (Arturo Duran),
--               se elimino la funcion de calcula_fechas y se adiciona la fn_calcula_mesesdias, para determinar 
--               cuantos meses, dias hay respecto a la fecha enviada
-----------------------------------------------------------------------------*/

	 FUNCTION FN_ACTUALIZA_CUP(VNIDEMISIONSF INT) RETURN NUMBER;

	 FUNCTION FN_CALCULA_MESESDIAS(vd_fecha date) RETURN NUMBER;

	 PROCEDURE PR_ACTUALIZA_BITACORA(VPIDEMISION NUMBER, VFECCB DATE, VFECED DATE, VFECECC DATE);

	 PROCEDURE CUP_SP_HOMOLOGA_FECHA;

END PKG_CUP_SP_HOMOLOGA_FECHA;
/

create or replace PACKAGE BODY PKG_CUP_SP_HOMOLOGA_FECHA
AS
-----------------------------------------------------------------------------
-- Creación: FEBRERO 23
-- Autor: JLCR
-- Descripción: HOMOLOGA FECHA DE EVALUACION_DESEMPENIO Y COMPETENCIAS_BASICAS
-- Modificación: De acurdo al Diagrama de flujo DiagrFlujoHomVigenciaEval_V1_23MAR23.pdf
--               Entregado por Arturo Durán, ya no se cambian fechas, unicamente se genera
--               registro en la tabla de bitacoras
-- Modificación: deacuerdo al documento CC_RNPSP_CUP_MarcadosCUIPS_V3.20.0_25042023.docx
--                         enviado por Arturo el día26 de Abr 23 
-- Modificación: 28 Junio 23, por observación de Arturo en actualizar el campo ESTATUS_FORMATO_SF a 0 que se realiza en la FN_ACTUALIZA_CUP
-- Modificacion: 12 JULIO 23, se adiciono la funcion de FN_CALCULA_FECHAS, por modularidad
-- Modificacion: 06 Marzo 24: solo debe tomar el ultimo registro de la tabla emision SF de cada persona
-----------------------------------------------------------------------------

        FUNCTION FN_CALCULA_MESESDIAS(vd_fecha date) RETURN NUMBER
            IS
            /******************************************************************************
         NAME: FN_CALCULA_MESESDIAS
         PURPOSE: funcion el calculo cuentos meses dias han pasado de fechas al dia hoy.

         REVISIONS:
         Ver Date Author Description
         --------- ---------- --------------- ------------------------------------
         1.0 06/01/2024 JLCR 1. Creación de la funcion

        ******************************************************************************/

        VANIOS NUMBER(5,3) := 0;
        VMESES NUMBER(5,3) := 0;
        VDIAS  NUMBER(5,3) := 0;

        BEGIN
            DBMS_OUTPUT.PUT_LINE('FECHA CALCULO...' ||' ' || TO_CHAR(vd_fecha));
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

            UPDATE EMISION_SF  
                 SET ESTATUS_CUP = 1, ESTATUS_FORMATO_SF = 0
             WHERE ID_EMISION_SF = VNIDEMISIONSF;

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

                INSERT INTO CUP_BIT_HOMOLOGA_FECHAS (ID_EMISION_SF, FECHA_EVALUACION_CB, FECHA_EVALUACION_ED, FECHA_ECCC)  
                VALUES (VPIDEMISION, VFECCB, VFECED,VFECECC );

            EXCEPTION 
            WHEN OTHERS   THEN 
                DBMS_OUTPUT.PUT_LINE('Problema en el Procedimiento PR_ACTUALIZA_BITACORA...' || TO_CHAR(VPIDEMISION));

        END PR_ACTUALIZA_BITACORA;


    PROCEDURE CUP_SP_HOMOLOGA_FECHA
    IS

CURSOR cr_verifica_sf IS
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
         AND SF.ID_EMISION_SF NOT IN (SELECT BHFC.ID_EMISION_SF FROM CUP_BIT_HOMOLOGA_FECHAS BHFC)
         --AND PER.CUIP IN (SELECT CUIP FROM CUIP_PBA_240208)
         ORDER BY sf.id_persona, sf.id_emision_sf DESC;

        REGCR_VERIFICA_SF CR_VERIFICA_SF%ROWTYPE;

        VNBANDERA NUMBER(1) := 0;

BEGIN

    OPEN CR_VERIFICA_SF;

        LOOP

        FETCH CR_VERIFICA_SF INTO REGCR_VERIFICA_SF;

        EXIT WHEN CR_VERIFICA_SF%NOTFOUND; -- Último registro;
DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' ' || to_char(FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC)));
        --La fecha transcurrida de la Evaluación de Control de Confianza es mayor a 3 años 0 meses 0 días (1)
            IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC) < 36.0
            THEN
            BEGIN
            IF REGCR_VERIFICA_SF.ID_COMPETENCIA_BASICA != 0 THEN --¿Existe registro de la evaluación de Competencias Básicas en el CUP ?
                DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' CB ' || to_char(FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_CB)));
                --La fecha de la Competencia Básica es 5 años <= a la fecha actual?    
                IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_CB) < 60.0            
                  THEN
                  DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' ¿ECCC > CB? ' );
                   DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' CB ' || to_char(FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC))
                   || to_char(FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_CB)));
                    --¿La fecha de la Evaluación de Control de Confianza > a  la Fecha de la Evaluación de Competencias Básicas?
                    IF REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC > REGCR_VERIFICA_SF.FECHA_EVALUACION_CB  THEN
                     DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' ECCC > CB ' );
                        --¿La Fecha de  Evaluación de Desempeño (Académico/Laboral) es 5 años menor a la fecha actual?
                        IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO) < 60.0 
                          THEN 
                            --¿La fecha de la Evaluación de Control de Confianza > a la Fecha de la Evaluación de Desempeño (Académico/Laboral)?
                            IF REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC > REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO  THEN

                                BEGIN
                                    --Actualiza el Estatus del CUP
                                    IF REGCR_VERIFICA_SF.ESTATUS_CUP = 0 THEN
                                        VNBANDERA := FN_ACTUALIZA_CUP(REGCR_VERIFICA_SF.ID_EMISION_SF);
                                    END IF;--(1 ACTUALIZA CUP)

                                    --Actualiza Bitacora
                                    PR_ACTUALIZA_BITACORA(REGCR_VERIFICA_SF.ID_EMISION_SF, REGCR_VERIFICA_SF.FECHA_EVALUACION_CB, REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO
                                   , REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC);

                                END;--(2 ACT BITACORA)

                            END IF;--(3 ECCC MAYOR ECC)

                        END IF;--(4 ED)

                    END IF;--(5 ECC MAYOR CB)

                END IF;--(6 MAYO A 60.0)
 
            ELSE

                 IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_CONCLUSION_FI) < 36.0
                 THEN
                        
                        --¿La fecha de la Evaluación de Control de Confianza > a la Fecha de la Evaluación de Desempeño (Académico/Laboral)?
                        IF REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC > REGCR_VERIFICA_SF.FECHA_CONCLUSION_FI THEN
                            
                                DBMS_OUTPUT.PUT_LINE('FECHA_CONCLUSION_FI...' || to_char(REGCR_VERIFICA_SF.ID_EMISION_SF)|| to_char(FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO)));
                                --¿La Fecha de  Evaluación de Desempeño (Académico/Laboral) es 5 años menor a la fecha actual?
                                IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO) < 60.0 
                                 THEN 
                                 
                                    --¿La fecha de la Evaluación de Control de Confianza > a la Fecha de la Evaluación de Desempeño (Académico/Laboral)?
                                    IF REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC > REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO THEN
        
                                        BEGIN
                                        DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' ¿ECCC > ED? ' );
                                        DBMS_OUTPUT.PUT_LINE('calculo...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)||' CB ' || to_char(FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO)));
                                            --Actualiza el Estatus del CUP
                                            IF REGCR_VERIFICA_SF.ESTATUS_CUP = 0 THEN
                                                VNBANDERA := FN_ACTUALIZA_CUP(REGCR_VERIFICA_SF.ID_EMISION_SF);
                                            END IF;
        
                                            --Actualiza Bitacora
                                            PR_ACTUALIZA_BITACORA(REGCR_VERIFICA_SF.ID_EMISION_SF, REGCR_VERIFICA_SF.FECHA_EVALUACION_CB, REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO, REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC);
        
                                        END;
        
                                    END IF;
                                    
                            END IF;

                    END IF;

                END IF;

            END IF;

        END;

        END IF; --(1)
 DBMS_OUTPUT.PUT_LINE('TERMINE...');
    COMMIT;

    END LOOP;

    CLOSE CR_VERIFICA_SF;

    EXCEPTION 
        WHEN OTHERS   THEN 
            DBMS_OUTPUT.PUT_LINE('Problema en el Procedimiento CUP_SP_HOMOLOGA_FECHA...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF));

END CUP_SP_HOMOLOGA_FECHA;

END PKG_CUP_SP_HOMOLOGA_FECHA;

--
--  (Synonym) 
--

CREATE OR REPLACE SYNONYM CUPAPP.PKG_CUP_SP_HOMOLOGA_FECHA FOR CUPADM.PKG_CUP_SP_HOMOLOGA_FECHA;

--
-- (grant) 
--

  GRANT EXECUTE ON "CUPADM"."PKG_CUP_SP_HOMOLOGA_FECHA" TO "CUPAPP";