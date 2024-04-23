CREATE OR REPLACE PACKAGE CUPADM.PKG_CUP_SP_CALCULO_CUP is
/******************************************************************************
-----------------------------------------------------------------------------
-- Creación: FEBRERO 23
-- Autor: JLCR
-- Descripción: ACTUALIZA, ESTATUS_CUP Y ESTATUS_FORMATO_SF DE ACURDO A LAS VIGENCIAS DE SUS EVALUACIONES
-- Modificación: Se Actualizo la logica conforme el diagram enviado por Arturo Dúran el Día 05/04/2023
--              documento de WORD CC_RNPSP_CUP_HomEvalu_V3.20.0 - V2.docx
-- Modificacion: 12 JULIO 23, se adiciono la funcion de FN_CALCULA_FECHAS, por modularidad
-- Modificación: 11 Diciembre 2023, conforme observaciones enviadas por El área de Analisis (Arturo Duran)
-----------------------------------------------------------------------------*/

--REGCR_VERIFICA_SF SYS_REFCURSOR;

  FUNCTION FN_ACTUALIZA_ESTATUS_CUP(VPIDEMISION NUMBER) RETURN NUMBER;

 FUNCTION FN_ACTUALIZA_SF(VPIDEMISION INT) RETURN NUMBER;

 FUNCTION FN_ACTUALIZA_EMISIONSF(VPIDEMISION INT) RETURN NUMBER;

 FUNCTION FN_ACTUALIZA_CUP_FUE(VPIDEMISION INT) RETURN NUMBER;

 FUNCTION FN_CALCULA_MESESDIAS(vd_fecha date) RETURN NUMBER;

 PROCEDURE CUP_SP_CALCULO_CUP;
 
END PKG_CUP_SP_CALCULO_CUP;

create or replace PACKAGE BODY PKG_CUP_SP_CALCULO_CUP
AS

    FUNCTION FN_ACTUALIZA_ESTATUS_CUP(VPIDEMISION NUMBER) RETURN NUMBER
    IS
    /******************************************************************************
     NAME: FN_ACTUALIZA_ESTATUS_CUP
     PURPOSE: funcion para actualizar el campo ESTATUS_CUP, en 0 = NO VIGENTE.

     REVISIONS:
     Ver Date Author Description
     --------- ---------- --------------- ------------------------------------
     1.0 26/12/2023 JLCR 1. Creación de la funcion

    ******************************************************************************/
    BEGIN

        UPDATE EMISION_SF
             SET ESTATUS_CUP = 0
           WHERE ID_EMISION_SF = VPIDEMISION;

        RETURN 1;
    EXCEPTION 
        WHEN NO_DATA_FOUND  THEN 
            RETURN 0;
        WHEN OTHERS   THEN 
            RETURN 0;

    END FN_ACTUALIZA_ESTATUS_CUP;

    FUNCTION FN_ACTUALIZA_SF(VPIDEMISION INT) RETURN NUMBER
    IS
    /******************************************************************************
     NAME: FN_ACTUALIZA_SF
     PURPOSE: funcion para actualizar el campo ESTATUS_FORMATO_SF, en 0 = NO VIGENTE.

     REVISIONS:
     Ver Date Author Description
     --------- ---------- --------------- ------------------------------------
     1.0 26/12/2023 JLCR 1. Creación de la funcion

    ******************************************************************************/
    BEGIN
        UPDATE EMISION_SF
            SET ESTATUS_FORMATO_SF = 0
           WHERE ID_EMISION_SF = VPIDEMISION;

        RETURN 1;
    EXCEPTION 
        WHEN NO_DATA_FOUND  THEN 
            RETURN 0;
        WHEN OTHERS   THEN 
            RETURN 0;

    END FN_ACTUALIZA_SF;

    FUNCTION FN_ACTUALIZA_EMISIONSF(VPIDEMISION INT) RETURN NUMBER
    IS
    /******************************************************************************
     NAME: FN_ACTUALIZA_EMISIONSF
     PURPOSE: funcion para actualizar el campo ESTATUS_FORMATO_SF, en 1= Vigente y ESTATUS_CUP a 0 = NO VIGENTE.

     REVISIONS:
     Ver Date Author Description
     --------- ---------- --------------- ------------------------------------
     1.0 26/12/2023 JLCR 1. Creación de la funcion

    ******************************************************************************/
    BEGIN
        UPDATE EMISION_SF
             SET ESTATUS_FORMATO_SF = 1
                , ESTATUS_CUP = 0
         WHERE ID_EMISION_SF = VPIDEMISION;

        RETURN 1;
    EXCEPTION 
        WHEN NO_DATA_FOUND  THEN 
            RETURN 0;
        WHEN OTHERS   THEN 
            RETURN 0;

    END FN_ACTUALIZA_EMISIONSF;

    FUNCTION FN_ACTUALIZA_CUP_FUE(VPIDEMISION INT) RETURN NUMBER
    IS
    /******************************************************************************
     NAME: FN_ACTUALIZA_CUP_FUE
     PURPOSE: funcion para actualizar el campo ESTATUS_FORMATO_SF, en 0 = NO VIGENTE y ESTATUS_CUP a 1 = VIGENTE.

     REVISIONS:
     Ver Date Author Description
     --------- ---------- --------------- ------------------------------------
     1.0 26/12/2023 JLCR 1. Creación de la funcion

    ******************************************************************************/
    BEGIN
        UPDATE EMISION_SF
             SET ESTATUS_FORMATO_SF = 0
                , ESTATUS_CUP = 1
         WHERE ID_EMISION_SF = VPIDEMISION;

        RETURN 1;
    EXCEPTION 
        WHEN NO_DATA_FOUND  THEN 
            RETURN 0;
        WHEN OTHERS   THEN 
            RETURN 0;

    END FN_ACTUALIZA_CUP_FUE;

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
        --DBMS_OUTPUT.PUT_LINE('FECHA CALCULO...' ||' ' || TO_CHAR(vd_fecha));
               VANIOS := TRUNC ( MONTHS_BETWEEN ( SYSDATE, TRUNC( vd_fecha )) / 12 );
               VMESES := TRUNC(MOD ( FLOOR ( MONTHS_BETWEEN ( SYSDATE, TRUNC ( vd_fecha) ) ), 12 ));
               VDIAS := TRUNC(SYSDATE - add_months(vd_fecha, trunc(months_between(SYSDATE, TRUNC ( vd_fecha )))));
               RETURN (VANIOS * 12) + VMESES + (VDIAS / 100);

        EXCEPTION 
            WHEN OTHERS   THEN 
                RETURN 0;
    END FN_CALCULA_MESESDIAS;

    PROCEDURE CUP_SP_CALCULO_CUP
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
         INNER JOIN prsnapp.persona per on per.ID_PERSONA = SF.ID_PERSONA
         LEFT JOIN formacion_inicial fi on FI.ID_FORMACION = SF.id_formacion
         LEFT JOIN competencia_basica CB on CB.ID_COMPETENCIA_BASICA = SF.ID_COMPETENCIA_BASICA
         LEFT JOIN evaluacion_desempenio ED on ED.ID_EVALUACION_DESEMPENIO = sf.ID_EVALUACION_DESEMPENIO
         INNER JOIN evaluacion@DB_ECCC EV ON EV."Id_Evaluacion" = SF.ID_ECCC AND EV."Id_Tipo_Evaluacion" IN (1,2)
         WHERE sf.EMISION_CUP IS NOT NULL AND sf.ESTATUS_CUP in (0,1)
         AND SF.ID_EMISION_SF IN (SELECT max(ESF.id_emision_sf) 
                              FROM emision_sf ESF
                             WHERE ESF.id_persona = sf.id_persona
                               AND ESF.emision_cup is not null)
         ORDER BY sf.id_persona, sf.id_emision_sf DESC;

        REGCR_VERIFICA_SF CR_VERIFICA_SF%ROWTYPE;

        VNBANDERA NUMBER(1) := 0;

        VNTIEMPO NUMBER(4,2) := 0.0;

BEGIN
    OPEN CR_VERIFICA_SF;

    LOOP

FETCH CR_VERIFICA_SF INTO REGCR_VERIFICA_SF;

        EXIT WHEN CR_VERIFICA_SF%NOTFOUND; -- Último registro;

        --- Tiempo a calcular 3 años o 5 años
        IF REGCR_VERIFICA_SF.CUMPLE = 0 THEN 
            VNTIEMPO := 36.0;
        ELSE
            VNTIEMPO := 60.0;
        END IF;
            --DBMS_OUTPUT.PUT_LINE('VNTIEMPO...' || TO_CHAR(VNTIEMPO));
            --verifica ECCC
            IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC) >= 36.0 
                    THEN 
                        IF REGCR_VERIFICA_SF.ESTATUS_FORMATO_SF = 1 AND REGCR_VERIFICA_SF.ESTATUS_CUP = 0 THEN 

                           VNBANDERA := FN_ACTUALIZA_SF(REGCR_VERIFICA_SF.ID_EMISION_SF);

                           GOTO BITACORA;

                        ELSIF REGCR_VERIFICA_SF.ESTATUS_FORMATO_SF = 0 AND REGCR_VERIFICA_SF.ESTATUS_CUP = 1 THEN
                            VNBANDERA := FN_ACTUALIZA_ESTATUS_CUP(REGCR_VERIFICA_SF.ID_EMISION_SF);

                            GOTO BITACORA;

                        ELSE

                            GOTO BITACORA;

                        END IF;

                END IF; --verifica ECCC

          --  DBMS_OUTPUT.PUT_LINE('TERMINA ECCC...');
                --Verifica Competencias Basicas
                IF REGCR_VERIFICA_SF.ID_COMPETENCIA_BASICA != 0 THEN 
                    IF  FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_CB) > VNTIEMPO --36.0
                        AND VNBANDERA = 0 THEN
                        BEGIN 

                            IF REGCR_VERIFICA_SF.ESTATUS_CUP = 1 THEN
                                VNBANDERA := FN_ACTUALIZA_EMISIONSF(REGCR_VERIFICA_SF.ID_EMISION_SF);
                                GOTO BITACORA;

                            ELSE
                                GOTO BITACORA;
                            END IF;

                        END;
                    END IF;
                ELSE
                    IF  FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_CONCLUSION_FI) > 36.0
                        AND VNBANDERA = 0 THEN
                        BEGIN 

                            IF REGCR_VERIFICA_SF.ESTATUS_CUP = 1 THEN
                                VNBANDERA := FN_ACTUALIZA_EMISIONSF(REGCR_VERIFICA_SF.ID_EMISION_SF);
                                GOTO BITACORA;

                            ELSE
                                GOTO BITACORA;
                            END IF;

                        END;
                    END IF;
                END IF;

                --Verifica Evaluacion Desempeño
                IF FN_CALCULA_MESESDIAS(REGCR_VERIFICA_SF.FECHA_EVALUACION_DESEMPENIO) > VNTIEMPO --36.0
                    AND VNBANDERA = 0 THEN
                    BEGIN 
                            IF REGCR_VERIFICA_SF.ESTATUS_CUP = 1 THEN
                                VNBANDERA := FN_ACTUALIZA_EMISIONSF(REGCR_VERIFICA_SF.ID_EMISION_SF);
                                GOTO BITACORA;

                            ELSE
                                GOTO BITACORA;
                            END IF;

                    END;
                ELSIF  REGCR_VERIFICA_SF.ESTATUS_CUP = 0 AND VNBANDERA = 0 THEN

                        VNBANDERA := FN_ACTUALIZA_CUP_FUE(REGCR_VERIFICA_SF.ID_EMISION_SF);
                END IF;

    --GENERA BITACORA DE MOVIMIENTOS

    <<BITACORA>>
    IF VNBANDERA = 1 THEN
        --DBMS_OUTPUT.PUT_LINE('GRABA BITACORA...' || TO_CHAR(REGCR_VERIFICA_SF.ID_EMISION_SF)|| ' '|| TO_CHAR(VNBANDERA));

       INSERT INTO CUP_BIT_CALCULO_CUP ( ID_EMISION_SF
        , ID_FORMACION
        , ID_EVALUACION_DESEMPENIO
        , ID_COMPETENCIA_BASICA
        , CUIP
        , ID_PERSONA
        , EMISION_CUP
        , ESTATUS_FORMATO_SF
        , ESTATUS_CUP
        , FECHA_EMISION_SF
        , ID_ECCC
        , FECHA_EVALUACION_ECCC
        , FECHA_VENCIMIENTO_ECCC)
            VALUES(REGCR_VERIFICA_SF.ID_EMISION_SF
            , REGCR_VERIFICA_SF.ID_FORMACION
            , REGCR_VERIFICA_SF.ID_EVALUACION_DESEMPENIO
            , REGCR_VERIFICA_SF.ID_COMPETENCIA_BASICA
            , REGCR_VERIFICA_SF.CUIP
            , REGCR_VERIFICA_SF.ID_PERSONA
            , REGCR_VERIFICA_SF.EMISION_CUP
            , REGCR_VERIFICA_SF.ESTATUS_FORMATO_SF
            , REGCR_VERIFICA_SF.ESTATUS_CUP
            , REGCR_VERIFICA_SF.FECHA_EMISION_SF
            , REGCR_VERIFICA_SF.ID_ECCC
            , REGCR_VERIFICA_SF.FECHA_EVALUACION_ECCC
            , REGCR_VERIFICA_SF.FECHA_VENCIMIENTO_ECCC);

        VNBANDERA := 0;
    END IF;

    VNTIEMPO := 00.0;

    COMMIT;

    END LOOP;

    CLOSE CR_VERIFICA_SF;

    EXCEPTION 
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('Problema en el Procedimiento CUP_SP_CALCULO_CUP...CUIP: ' || REGCR_VERIFICA_SF.CUIP);

END CUP_SP_CALCULO_CUP;

END PKG_CUP_SP_CALCULO_CUP;

--
-- CAT_ESTATUS_HOMOLOGA  (Synonym) 
--

CREATE OR REPLACE SYNONYM CUPAPP.PKG_CUP_SP_CALCULO_CUP FOR CUPADM.PKG_CUP_SP_CALCULO_CUP;

--
-- (grant) 
--

  GRANT EXECUTE ON "CUPADM"."PKG_CUP_SP_CALCULO_CUP" TO "CUPAPP";