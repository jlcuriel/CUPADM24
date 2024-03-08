-- CUPADM.CUP_BIT_CALCULO_CUP definition

CREATE TABLE CUPADM.CUP_BIT_CALCULO_CUP
(
  ID_BIT_CALCULO_CUP        NUMBER,
  ID_EMISION_SF             NUMBER(10)          NOT NULL,
  ID_FORMACION              NUMBER(10)          NOT NULL,
  ID_EVALUACION_DESEMPENIO  NUMBER(10),
  ID_COMPETENCIA_BASICA     NUMBER(10)          NOT NULL,
  CUIP                      VARCHAR2(20 BYTE)   NOT NULL,
  ID_PERSONA                NUMBER(10)          NOT NULL,
  EMISION_CUP               VARCHAR2(40 BYTE),
  ESTATUS_FORMATO_SF        NUMBER(1)           NOT NULL,
  ESTATUS_CUP               NUMBER(1)           NOT NULL,
  FECHA_EMISION_SF          DATE,
  ID_ECCC                   NUMBER(10),
  FECHA_EVALUACION_ECCC     DATE,
  FECHA_VENCIMIENTO_ECCC    DATE,
  FECHA_DE_CALCULO          DATE                DEFAULT sysdate               NOT NULL
)
TABLESPACE CUP_DATA01
PCTUSED    40
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          2688
            NEXT             512
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;

--COMENTARIO
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_BIT_CALCULO_CUP IS 'Clave �nica del registro de la bitacora';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_EMISION_SF IS 'Clave �nica del registro de emisi�n del formato �nico';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_FORMACION IS 'Clave �nica de la formaci�n inicial del personal';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_EVALUACION_DESEMPENIO IS 'Clave �nica de del registro de la evaluaci�n';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_COMPETENCIA_BASICA IS 'Clave �nica de del registro de la evaluaci�n';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.CUIP IS 'Clave �nica de Identificaci�n Policial de la tabla PERSONA del esquema RNPSP';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_PERSONA IS 'Identificador �nico, se deriva de la tabla PERSONA del esquema RNPSP';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.EMISION_CUP IS 'Clave CUP emitido para la persona evaluada';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ESTATUS_FORMATO_SF IS 'Estatus en que se encuentra el formato SF (Single Format) "Formato Unico", 0 = invalido, 1 = valido';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ESTATUS_CUP IS 'Estatus en que se encuentra el CUP SEF, 0 = no vigente, 1 = vigente, 2 = Cancelaci�n';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.FECHA_EMISION_SF IS 'Fecha de impresi�n del Formato SF (Single Format) "Formato Unico"';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.ID_ECCC IS 'Identificador �nico del registro de la tabla del certificado de control de confianza, se obtiene de la BD de SQLServer';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.FECHA_EVALUACION_ECCC IS 'Fecha de evaluacion del ECCC tabla evaluacion de la BD ECCC';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.FECHA_VENCIMIENTO_ECCC IS 'Fecha de vencimiento del ECCC';
COMMENT ON COLUMN CUPADM.CUP_BIT_CALCULO_CUP.FECHA_DE_CALCULO IS 'Fecha en que se realizo el preceso';


--INDEX
CREATE INDEX CUPADM.CUP_IDX_BIT_CALCULOCUP ON CUPADM.CUP_BIT_CALCULO_CUP
(ID_BIT_CALCULO_CUP)
LOGGING
TABLESPACE CUP_DATA01
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          35M
            NEXT             18M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOPARALLEL;

--TRIGGER
CREATE OR REPLACE TRIGGER CUPADM.TRG_CUP_BIT_CALCULOCUP
BEFORE INSERT
ON CUPADM.CUP_BIT_CALCULO_CUP REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
-- For Toad:  Highlight column ID_BIT_CALCULO_CUP
  :new.ID_BIT_CALCULO_CUP := SEQ_CUP_BITCALCULOCUP.nextval;
END TRG_CUP_BIT_CALCULOCUP;
/

--SYNONIMO
CREATE OR REPLACE SYNONYM CUPAPP.CUP_BIT_CALCULO_CUP FOR CUPADM.CUP_BIT_CALCULO_CUP;

--PK
ALTER TABLE CUPADM.CUP_BIT_CALCULO_CUP ADD (
  CONSTRAINT PK_CUP_CALCULO_CUP
  PRIMARY KEY
  (ID_BIT_CALCULO_CUP)
  USING INDEX CUPADM.CUP_IDX_BIT_CALCULOCUP);

--GRANT
GRANT INSERT, SELECT, UPDATE ON CUPADM.CUP_BIT_CALCULO_CUP TO CUPAPP;