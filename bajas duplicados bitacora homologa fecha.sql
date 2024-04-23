--
--borra todo los registros duplicados de la tabla de bitacora de CUP "CUP_BIT_HOMOLOGA_FECHAS"
--

delete cupadm.CUP_BIT_HOMOLOGA_FECHAS a
where a.id_emision_sf in (
                    select b.id_emision_sf
                    from cupadm.emision_sf a
                    inner join cupadm.CUP_BIT_HOMOLOGA_FECHAS b on a.id_emision_sf = b.id_emision_sf
                    where a.id_persona in (select id_persona
                                    from cupadm.emision_sf a
                                    inner join cupadm.CUP_BIT_HOMOLOGA_FECHAS b on a.id_emision_sf = b.id_emision_sf
                                    group by id_persona
                                    having count(1) > 1)