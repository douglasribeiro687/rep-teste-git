--+ 

DECLARE
  tag_p                         VARCHAR2(10) := '<p>';
  tag_h3                        VARCHAR2(10) := '<h3>';
  tagf_h3                       VARCHAR2(10) := '</h3>';
  
  v_ano_lancto                  NUMBER := TO_CHAR ( SYSDATE - 1, 'YYYY');
  v_mes_lancto                  NUMBER := TO_CHAR ( SYSDATE - 1, 'MM');  
  v_count                       NUMBER;
  v_total_leituras              NUMBER;
  v_total_ligacao               NUMBER;
  v_count_consumofinal          NUMBER;
  leit_nao_realizada            NUMBER := 907;  
  
  v_sqlerrm                     VARCHAR2(1000);  
  v_processo                    LONG;
  v_separador                   VARCHAR2(500) := CHR(10) || CHR(10) || tag_p || '*********************************************************************' || CHR(10) || CHR(10) || tag_p;
--  v_separador                   VARCHAR2(500) := CHR(10) ||  '*********************************************************************' ||  CHR(10) ;
  v_dt_ini                      DATE;
  v_dt_fim                      DATE;
  
  ErrorMessage1       VARCHAR2(4000);
  ErrorStatus         NUMBER;    
      
  
  FUNCTION executa_comando(comando     IN VARCHAR2, dblink_cliente     IN VARCHAR2, pretorno    IN CHAR DEFAULT 0) RETURN NUMBER
  IS
        resultado                   NUMBER;
        v_sql                       VARCHAR2(32000);
  BEGIN 
     
      IF dblink_cliente IS NOT NULL 
      THEN 
        
        v_sql := REPLACE(comando, 'DB_LINK', dblink_cliente);
      
      ELSE 
        
        v_sql := REPLACE(comando, '@DB_LINK', NULL);
        
      END IF;       
      
      IF NVL(pretorno, 0) = 0 
      THEN
      
        EXECUTE IMMEDIATE ( v_sql ) INTO resultado;
        
      ELSE 
      
        EXECUTE IMMEDIATE ( v_sql );
      END IF;
    
      RETURN NVL(resultado, 0);
      
  END;  

  PROCEDURE send_mail2 (p_assunto IN VARCHAR2,
                                       p_mensagem IN VARCHAR2)                                       
    AS
      
      ---- endereços para envio ---
      TYPE v IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
      p_to_list        v;
      
      l_mail_conn     UTL_SMTP.connection; 
      v_mail_from     VARCHAR2(100) := 'emailsistemas@gmfsaneamento.com.br';
      v_pass          VARCHAR2(20)  := 'sup#2016';
      p_to            VARCHAR2(1000);         
      p_from          VARCHAR2(100) := 'emailsistemas@gmfsaneamento.com.br';   
      p_smtp_host     VARCHAR2(100) := 'smtp.gmfsaneamento.com.br';
      p_smtp_port     NUMBER        := 587;
      
      p_formato       VARCHAR2(20)  := 'text';
      
      
      FUNCTION GET_ADDRESS
         (ADDR_LIST IN OUT VARCHAR2
         )
         RETURN VARCHAR2
         IS

            addr VARCHAR2(256);
            i    pls_integer;

            FUNCTION lookup_unquoted_char(str  IN VARCHAR2,
                          chrs IN VARCHAR2) RETURN pls_integer AS
              c            VARCHAR2(5);
              i            pls_integer;
              len          pls_integer;
              inside_quote BOOLEAN;
            BEGIN
               inside_quote := false;
               i := 1;
               len := length(str);
               WHILE (i <= len) LOOP

             c := substr(str, i, 1);

             IF (inside_quote) THEN
               IF (c = '"') THEN
                 inside_quote := false;
               ELSIF (c = '\') THEN
                 i := i + 1; -- Skip the quote character
               END IF;
               GOTO next_char;
             END IF;

             IF (c = '"') THEN
               inside_quote := true;
               GOTO next_char;
             END IF;

             IF (instr(chrs, c) >= 1) THEN
                RETURN i;
             END IF;

             <<next_char>>
             i := i + 1;

               END LOOP;

               RETURN 0;

            END;
        BEGIN

            addr_list := ltrim(addr_list);
            i := lookup_unquoted_char(addr_list, ',;');
            IF (i >= 1) THEN
              addr      := substr(addr_list, 1, i - 1);
              addr_list := substr(addr_list, i + 1);
            ELSE
              addr := addr_list;
              addr_list := '';
            END IF;

            i := lookup_unquoted_char(addr, '<');
            IF (i >= 1) THEN
              addr := substr(addr, i + 1);
              i := instr(addr, '>');
              IF (i >= 1) THEN
            addr := substr(addr, 1, i - 1);
              END IF;
            END IF;

        -- aqui    RETURN addr;

            RETURN '<' || addr || '>' ;
          END;
    BEGIN
      
      p_to_list(1) := 'douglas.dasilva@gssbr.com.br';
--      p_to_list(2) := 'dougrock.douglas@gmail.com';
--      p_to_list(2) := 'arequejo@gmfsaneamento.com.br';
      
      --- ADICIONAR NA LISTA OS DESTINATARIOS QUE DESEJAR ---
      --p_to_list(3) := 'dougrock.douglas@gmail.com';
      
      --- IDENTIFICA O FORMATO DO EMAIL ---
      IF UPPER(p_mensagem) LIKE '%<HTML>%' THEN 
         p_formato := 'text/html';
      END IF;

      l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
      UTL_SMTP.helo(l_mail_conn, p_smtp_host);
      
      SYS.UTL_SMTP.command (l_mail_conn, 'AUTH LOGIN');
      SYS.UTL_SMTP.command (l_mail_conn, UTL_RAW.cast_to_varchar2 (UTL_ENCODE.base64_encode (UTL_RAW.cast_to_raw (v_mail_from)))); 
      SYS.UTL_SMTP.command (l_mail_conn, UTL_RAW.cast_to_varchar2 (UTL_ENCODE.base64_encode (UTL_RAW.cast_to_raw (v_pass))));
      
      SYS.UTL_SMTP.mail(l_mail_conn, p_from);
        
      FOR i IN 1 .. p_to_list.COUNT LOOP 
          dbms_output.put_line('p_to_list(i)=' || p_to_list(i) );
          SYS.utl_smtp.rcpt(l_mail_conn, p_to_list(i) );
          
          p_to := p_to || ' ; ' ||p_to_list(i);
      END LOOP;
      
      SYS.UTL_SMTP.open_data(l_mail_conn);
      
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf) );
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'To: ' || p_to || UTL_TCP.crlf) );
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'From: ' || p_from || UTL_TCP.crlf) );
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'Subject: ' || p_assunto || UTL_TCP.crlf) );
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'Reply-To: ' || p_from || UTL_TCP.crlf) );
--      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'Content-Type: text' || UTL_TCP.crlf) );
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( 'Content-Type: ' || p_formato || '; charset=iso-8859-1' || UTL_TCP.crlf) );
      
      --sys.utl_smtp.WRITE_RAW_DATA(conn, UTL_RAW.CAST_TO_RAW( name || ': ' || value || utl_tcp.CRLF) );
           
      SYS.UTL_SMTP.write_raw_data(l_mail_conn, UTL_RAW.CAST_TO_RAW( p_mensagem || UTL_TCP.crlf || UTL_TCP.crlf) );
      SYS.UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
      
      SYS.UTL_SMTP.close_data(l_mail_conn);
      SYS.UTL_SMTP.quit(l_mail_conn);
      
    END;
  
BEGIN 
               
     FOR I IN (
     
            
                   SELECT sq_contrato,
                   ds_contrato,
                   (SELECT username
                      FROM all_db_links
                     WHERE UPPER (username) = UPPER (ds_conexao_owner))
                      dblink_cliente
              FROM portal_contratos p
             WHERE ic_ativo = 'S' AND UPPER (ds_conexao_owner) NOT LIKE 'K%'
               AND cl_ambiente = 'P'
               and sq_contrato in ( 611, 888, 633, 611, 866, 577, 622, 488, 41, 588, 911, 888 ) 
                   --AND sq_contrato IN ( 20, 68, 18, 61, 62, 63, 44, 46, 21, 25, 19, 45, 56, 50, 55, 56, 57, 58, 64, 65, 67, 69, 66, 68, 81,
                                         --   84, 80, 77, 76, 71, 78, 70, 75, 73, 79, 72, 74, 86, 88, 89) 
               )
     LOOP 
     
     ------- PROBLEMA DETECTADO - QTD. DE ECONOMIAS  X HISTOGRAMA ------
     v_processo := '<!DOCTYPE html>' || CHR(10) ||
                   '<html>'          || CHR(10) ||
                   '<head>'          || CHR(10) ||
                   '<style>'         || CHR(10) ||
                   'h3{color: red;}' || CHR(10) ||
                   '</style>'        || CHR(10) ||
                   '</head>'         || CHR(10) ||
                   '<body>'          || CHR(10) ||
                tag_p ||
                '//////////////////////////////////////  ' || UPPER( I.ds_contrato ) || ' //////////////////////////////////////' || CHR(10) || CHR(10) ||
                tag_p || 
                'VALIDAÇÃO BASE DE DADOS REF. ' || LPAD(v_mes_lancto, 2, '0') || '/' || v_ano_lancto || CHR(10) ||
                tag_p || 
                'Inicio em ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI');
     
     v_dt_ini := SYSDATE;           
     
     BEGIN 
     
        v_count :=
        executa_comando ('
          SELECT COUNT (*)  
            FROM leitura@DB_LINK a
           WHERE a.ano_lancto = ' || v_ano_lancto || ' AND a.mes_lancto = ' || v_mes_lancto || 
                 ' AND NOT EXISTS
                            (SELECT 1
                               FROM vew_lancamentos@DB_LINK v
                              WHERE     a.num_ligacao = v.num_ligacao 
                                    AND a.mes_lancto = v.mes_lancto
                                    AND a.ano_lancto = v.ano_lancto
                                    AND a.zona_ligacao = v.zona_ligacao) ' , I.dblink_cliente);

     EXCEPTION WHEN OTHERS THEN
           
        v_sqlerrm := SQLERRM || ' (ERRO TECNICO 001 - VALIDAR SE EXISTE LANCAMENTO PARA TODAS AS LEITURAS) !!!' ;
           
     END;
     
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '001 - Inconsistencia: Não existe lancamento para todas as leituras! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||
                          '001 - OK - Existe lançamento para todas as leituras!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_count   := 0;
     v_sqlerrm := NULL;
     
     --------------- SALDO CONTABIL -------------
     BEGIN 

         v_count := executa_comando ('BEGIN DELETE batimento_nota_aux@DB_LINK; COMMIT; END;', I.dblink_cliente, 1);

         v_count := 
         executa_comando ('BEGIN ' ||
                            ' INSERT INTO batimento_nota_aux@DB_LINK
                              SELECT S.num_nota
                                   , S.cod_tributo
                                   , s.num_ligacao
                                   , s.mes_lancto
                                   , s.ano_lancto           
                                   , nvl (sum (s.val_saldo), 0) val_saldo_nota
                                   , nvl (sum (l.val_lancto), 0) val_lancto
                              FROM (select g.num_nota, g.val_lancto, g.cod_tributo
                                      from vew_lancamentos@DB_LINK g
                                     where sit_pagto = ''D''
                                       and num_nota > 0
                                       and num_aviscred = 0
                                       and cod_tributo in (1, 2)) l,
                                   (select   nt.num_nota, nt.num_ligacao, nt.mes_lancto, nt.ano_lancto,
                                             nt.cod_tributo,
                                             sum (decode (nt.sit_notafiscal,
                                                          ''DE'', (nt.val_lancto),
                                                          ((nt.val_lancto) * -1)
                                                         )
                                                 ) val_saldo
                                        from nota_fiscal@DB_LINK nt 
                                      where nt.num_nota not in (SELECT NUM_NOTA FROM NOTA_FISCAL_AUX3@DB_LINK) 
                                        and nt.sit_notafiscal in (''DE'', ''CA'', ''CM'', ''TA'', ''PV'',''CV'')
                                    --and  nvl(nt.dat_evento,nt.dat_emissao) < SYSDATE
                                    group by nt.num_nota,
                                             nt.num_ligacao,
                                             nt.mes_lancto,
                                             nt.ano_lancto,
                                             nt.cod_tributo) s
                             where l.num_nota(+) = s.num_nota
                               and l.cod_tributo(+) = s.cod_tributo
                               AND NVL (l.val_lancto, 0) <> NVL (s.val_saldo, 0)
                        group by S.num_nota
                               , S.cod_tributo
                               , s.num_ligacao
                               , s.mes_lancto
                               , s.ano_lancto; ' || 
                      ' COMMIT; ' || 
                      ' END; ', I.dblink_cliente, 1);
               
        v_count := executa_comando ('SELECT COUNT(*) FROM batimento_nota_aux@DB_LINK ', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (ERRO TECNICO 010 - BATIMENTO NOTA FISCAL - SALDO CONTABIL) !!!';     
     END;
          
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                     
                          '010 - Inconsistencia: Verificar tabela de apoio BATIMENTO_NOTA_AUX! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '010 - OK - Não existe divergencia no saldo contábil!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_count   := 0;
     v_sqlerrm := NULL;     

     ---- PROBLEMA COM ESTORNO DE PARCELAMENTO ----
     BEGIN
     
            v_count :=
            executa_comando ('
            SELECT COUNT(*)
              FROM TERMO_PARCELAMENTO@DB_LINK T, NOTA_FISCAL@DB_LINK NN
             WHERE     NN.NUM_LIGACAO = T.NUM_LIGACAO
                   AND NN.SIT_NOTAFISCAL = ''TE''
                   AND TO_CHAR (T.DAT_ESTORNO, ''YYYYMM'') >= ''201409''
                   AND NOT EXISTS
                              (SELECT NULL
                                 FROM NOTA_FISCAL@DB_LINK NNN
                                WHERE     T.NUM_LIGACAO = NNN.NUM_LIGACAO
                                      AND T.ZONA_LIGACAO = NNN.ZONA_LIGACAO
                                      AND NNN.NUM_NOTA = NN.NUM_NOTA
                                      AND NNN.SEQ_NOTA = NN.SEQ_NOTA
                                      AND NNN.SIT_NOTAFISCAL = ''TE''
                                      AND NNN.DAT_EVENTO =
                                             TO_NUMBER (
                                                TO_CHAR (T.DAT_ESTORNO, ''YYYYMMDD'')))
                   AND NOT EXISTS
                              (SELECT NULL
                                 FROM NOTA_FISCAL@DB_LINK NT
                                WHERE NT.NUM_NOTA = NN.NUM_NOTA
                                      AND NT.SIT_NOTAFISCAL = ''TE''
                                      AND NT.DAT_EVENTO =
                                             TO_NUMBER (
                                                TO_CHAR (T.DAT_ESTORNO, ''YYYYMMDD'')))
                   AND NOT EXISTS
                              (SELECT NULL
                                 FROM nota_fiscal@DB_LINK no, TERMO_PARCELAMENTO@DB_LINK TE
                                WHERE     no.num_nota = nn.num_nota
                                      AND no.sit_notafiscal = ''TE''
                                      AND NO.NUM_LIGACAO = TE.NUM_LIGACAO
                                      AND NO.ZONA_LIGACAO = TE.ZONA_LIGACAO
                                      AND NO.DAT_EVENTO =
                                             TO_NUMBER (
                                                TO_CHAR (TE.DAT_ESTORNO, ''YYYYMMDD''))) ' , I.dblink_cliente);
                                            
                                            
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 015 - INCONSISTENCIAS EM ESTORNOS DE PARCELAMENTO) !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '015 - Inconsistencia: Verificar estornos de parcelamento! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '015 - OK - Não existe problema nos estornos de parcelamento!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
                                    
     v_count   := 0;
     v_sqlerrm := NULL;     
    
     ---- VALOR DA CONTA DIFERENTE DO ITEM DA CONTA -----     
     BEGIN
     
        --SELECT l.num_ligacao, l.mes_lancto, l.ano_lancto, L.val_lancto, IT.tot_item, IT.val_tot_item
        v_count :=
        executa_comando ('
        SELECT COUNT(*)
          FROM lancamento@DB_LINK L,
               (SELECT COUNT(*) tot_item, I.num_aviso, I.ano_lancto, I.num_emissao, SUM(val_parcela) val_tot_item
                  FROM item_lancamento@DB_LINK I
                 GROUP BY I.num_aviso, I.ano_lancto, I.num_emissao) IT 
         WHERE L.ano_lancto = ' || v_ano_lancto ||  
         ' AND L.mes_lancto = ' || v_mes_lancto || 
         ' AND L.num_aviso = IT.num_aviso 
           AND L.ano_lancto = IT.ano_lancto
           AND L.num_emissao = IT.num_emissao
           AND l.val_lancto <> it.val_tot_item
           AND SUBSTR( l.dsc_simultanea, 1, 2) <> ''99'' ' , I.dblink_cliente);
                       

     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 020 - VALOR (R$) DO LANCAMENTO NAO CONFERE COM A SOMA DOS ITENS) !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador ||  tag_h3 ||                      
                          '020 - Inconsistencia: Verificar valor da conta nao confere com a soma dos itens! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '020 - OK - Não existe divergencia nos valores de conta e item!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;   
   
     v_sqlerrm := NULL;
     v_count   := 0;

     --- CONTA SEM ITEM LANCAMENTO ----
     BEGIN

            /*SELECT LE.num_ligacao, LA.num_aviso, LA.ano_lancto, 
                   LA.num_emissao, le.con_medido, le.con_faturado_a,
                   LE.dsc_simultanea, LA.dsc_simultanea, le.dat_transmissao,
                   le.cod_leitura_int
            */
            v_count :=
            executa_comando ('
            SELECT COUNT(*)  
              FROM leitura@DB_LINK LE, lancamento@DB_LINK LA 
             WHERE LA.zona_ligacao = LE.zona_ligacao
               AND LA.num_ligacao = LE.num_ligacao
               AND LA.mes_lancto = LE.mes_lancto
               AND LA.ano_lancto = LE.ano_lancto
               AND LE.cod_leitura_int <> 907
               AND LE.ano_lancto = ' || v_ano_lancto ||
             ' AND LE.mes_lancto = ' || v_mes_lancto ||
             ' AND NOT EXISTS
                      (SELECT NULL
                         FROM item_lancamento@DB_LINK I
                        WHERE I.num_aviso = LA.num_aviso
                          AND I.ano_lancto = LA.ano_lancto
                          AND I.mes_lancto = LA.mes_lancto
                          AND NVL(I.num_servico, 0) = 0
                       ) ' , I.dblink_cliente);

     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 025 - CONTA MENSAL SEM REGISTRO DOS ITENS) !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '025 - Inconsistencia: Verificar conta sem item lancamento! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '025 - OK - Todas as contas da referencia contém item lancamento!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;                   

     v_sqlerrm := NULL;
     v_count   := 0;                   

     ----- CONTAS SEM LANCAMENTO TARIFA ----- 
     BEGIN

         --SELECT  v.num_ligacao, l.dsc_simultanea, l.dat_leitura, l.hor_leitura, v.sit_ligacao
           v_count :=
           executa_comando ('
           SELECT COUNT(*)          
             FROM leitura@DB_LINK v FULL JOIN lancamento_tarifa@DB_LINK lt
                  ON ((    v.num_ligacao = lt.num_ligacao
                       AND v.ano_lancto = lt.ano_lancto
                       AND v.mes_lancto = lt.mes_lancto
                       AND v.zona_ligacao = lt.zona_ligacao
                      )
                     )                
                  FULL JOIN leitura@DB_LINK l
                  ON (    v.num_ligacao = l.num_ligacao
                      AND v.ano_lancto = l.ano_lancto
                      AND v.mes_lancto = l.mes_lancto
                      AND v.zona_ligacao = l.zona_ligacao
                     )
            WHERE l.cod_leitura_int <> 907
              AND l.ano_lancto = ' || v_ano_lancto || 
            ' AND l.mes_lancto = ' || v_mes_lancto ||
            ' AND v.con_faturado_a > 0 AND v.crt_excecao <> 50 -- APENAS CONTA COM FATURAMENTO GERAM LANCAMENTO_TARIFA --
              AND v.con_faturado_a >= v.con_minimo
              AND SUBSTR (v.dsc_simultanea, 1, 2) NOT IN (10, 99) --- ISENTA-NÃO IMPRESSA, SENDO ENTREGUE ---
              AND (lt.num_ligacao IS NULL ) ' , I.dblink_cliente);
              
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 030 - VALIDAR LEITURA SEM LANCAMENTO TARIFA) !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '030 - Inconsistencia: Verificar leitura sem registro de lancamento tarifa! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '030 - OK - Todas as leituras tem registro de lancamento tarifa!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;                                                

     v_sqlerrm := NULL;
     v_count   := 0;            

     ---- CONTAS SEM CONTROLE_NOTA --> PROBLEMA PARA EMISSÃO DA NOTA FISCAL ----
     BEGIN
     
        --SELECT num_aviso, ano_lancto, num_emissao, cod_tributo, 'A1' num_serie_nota, mes_lancto,
        --       zona_ligacao, num_ligacao, 'N' sta_reinicializa,num_nota
        v_count :=
        executa_comando ('
            SELECT SUM( tot ) 
              FROM (
                    SELECT COUNT(*) TOT   
                      FROM lancamento@DB_LINK l
                     WHERE ano_lancto = ' || v_ano_lancto || 
                     ' AND mes_lancto = ' || v_mes_lancto ||
                     ' AND NOT EXISTS
                              (SELECT 1
                                 FROM controle_nota@DB_LINK c
                                WHERE     c.num_aviso = l.num_aviso
                                      AND c.ano_lancto = l.ano_lancto
                                      AND c.num_emissao = l.num_emissao)
                    UNION ALL 
                    SELECT COUNT(*) TOT
                      FROM taxa_diversa@DB_LINK t
                         WHERE ano_lancto = ' || v_ano_lancto || 
                         ' AND mes_lancto = ' || v_mes_lancto ||
                         ' AND NOT EXISTS (SELECT 1 
                                          FROM controle_nota@DB_LINK c
                                         WHERE c.num_aviso = t.num_aviso 
                                           AND c.ano_lancto = t.ano_lancto
                                           AND c.num_emissao = t.num_emissao)
                   ) ', I.dblink_cliente);
                    
                                   
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 035 - VALIDAR LANCAMENTO SEM CONTROLE NOTA (CONTA MENSAL OU TAXA DIVERSA) !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '035 - Inconsistencia: Verificar lancamento sem registro no controle nota (N.F.C. OU N.F.A.)! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '035 - OK - Todos os lancamentos tem registro no controle nota (N.F.C. e N.F.A.)!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;    
     
     v_sqlerrm := NULL;
     v_count   := 0;                                  
                                   
     --- TAXA DIVERSA SEM NOTA FISCAL

     BEGIN 

        --SELECT mes_lancto, ano_lancto, num_ligacao, dat_vencto, val_lancto, cod_usuario, sit_pagto, num_aviso
        v_count :=
        executa_comando ('
            SELECT COUNT(*)
              FROM taxa_diversa@DB_LINK
             WHERE num_nota = 0 AND sit_pagto <> ''C'' -- CANCELADA -- ', I.dblink_cliente); 
         
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 040 - VALIDAR TAXA DIVERSA SEM NOTA FISCAL !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '040 - Inconsistencia: Verificar taxa diversa sem registro na nota fiscal! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '040 - OK - Todas as taxas diversas tem registro na nota fiscal!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
       
     v_sqlerrm := NULL;
     v_count   := 0;
     
     --- SERVICOS GERADOS NA ARRECADACAO QUE NAO FORAM LANCADOS 
     BEGIN 
     
--     SELECT i.num_aviso, i.ano_lancto, i.num_emissao, i.num_ligacao,
--             i.mes_lancto, i.val_autenticado,  i.val_apurado, i.val_diferenca,
--             i.sit_pagto, i.dat_atualiz, i.num_aviscred, i.ano_aviscred, i.num_slip     
       
        v_count :=
            executa_comando ('
                 SELECT COUNT(*)
                   FROM slip@DB_LINK i, aviso_credito@DB_LINK a
                  WHERE i.num_aviscred = a.num_aviscred
                    AND i.ano_aviscred = a.ano_aviscred    
                    and a.sit_aviscred = ''A''
                    AND i.ano_aviscred = ' || v_ano_lancto ||
                  ' AND i.sit_pagto IN (''D'', ''B'', ''C'', ''A'', ''W'', ''+'', ''-'')
                    AND NVL (num_ligacao, 0) > 0
                    AND i.seq_responsavel IS NOT NULL
                    AND i.val_diferenca <> 0 
                    AND NOT EXISTS
                               (SELECT 1
                                  FROM servico@DB_LINK s
                                 WHERE     s.num_ligacao = i.num_ligacao
                                       AND s.zona_ligacao = i.zona_ligacao
                                       AND s.cod_rubrica = (SELECT cod_rubr_dev_guia FROM geral@DB_LINK)
                                       AND ABS (i.val_diferenca) = ABS (s.val_servico) 
                                )', I.dblink_cliente);
                            
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 045 - VALIDAR SERVICOS DE DEBITO/CREDITO GERADOS NA ARRECADACAO !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                     
                          '045 - Inconsistencia: Verificar serviços (deb/cred) gerados na arrecadacao que não foram lançados! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '045 - OK - Nenhuma inconsistencia no lancamento de serviço (deb/cred) referente a arrecadacao!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
       
     v_sqlerrm := NULL;
     v_count   := 0;      
          
     --- SERVICOS DE DEVOLUCAO LANCADOS COM VALOR ERRADO, DEVERIA SER DESCONTO E FOI LANCADO COMO COBRANCA
     BEGIN      
--        SELECT s.num_ligacao, s.cod_tributo, s.mes_lancto,
--               s.ano_lancto, s.num_aviso, s.sit_pagto,
--               s.num_slip, s.num_aviscred, s.ano_aviscred,
--               s.num_lote, s.val_diferenca, s.dat_atualiz,
--               e.val_servico, e.obs_servico, it.sit_parcela,
--               LPAD(e.mes_lancto, 2, '0') || '/' || e.ano_lancto ref_servico_lancado
        v_count :=
            executa_comando ('
                SELECT COUNT(*)
                  FROM slip@DB_LINK s, servico@DB_LINK e, item_servico@DB_LINK it
                 WHERE s.num_ligacao = e.num_ligacao
                   AND s.zona_ligacao = e.zona_ligacao
                   AND e.num_servico = it.num_servico               
                   AND e.cod_rubrica = ( SELECT cod_rubr_dev_guia FROM geral@DB_LINK )
                   AND UPPER(e.obs_servico) like ''DIF.DA ARRECADAÇÃO%''
                   AND s.sit_pagto IN (''D'', ''B'', ''C'', ''A'', ''W'')
                   AND s.val_diferenca > 0
                   AND it.sit_parcela = 0 ', I.dblink_cliente);

     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 050 - VALIDAR SERVICOS DE CREDITO LANCADOS COMO COBRANCA !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '050 - Inconsistencia: Verificar servico de credito gerado como cobranca! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '050 - OK - Nenhuma inconsistencia no lancamento de serviço de credito!';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF; 
       
     v_sqlerrm := NULL;
     v_count   := 0;       
--     
--     DECLARE
--        v_rub_agua              NUMBER;
--        v_rub_esgoto            NUMBER;
--        v_rub_esgoto_esp        NUMBER;        
--     ---RUBRICAS DE FATURAMENTO DUPLICADAS
--     BEGIN 
--     
--        SELECT cod_rubr_agu, cod_rubr_esg, cod_rubr_especial
--          INTO v_rub_agua, v_rub_esgoto, v_rub_esgoto_esp
--          FROM cronograma 
--         WHERE ano_lancto = v_ano_lancto
--           AND mes_lancto = v_mes_lancto
--           AND ROWNUM < 2;
--        
--        --SELECT LIGA.*, LA.NUM_LIGACAO, LA.NUM_NOTA
--        SELECT COUNT(*)
--          INTO v_count
--          FROM lancamento la, 
--               (  
--                    SELECT   COUNT (1), i.ano_lancto, i.num_emissao, i.num_aviso, i.cod_rubrica
--                        FROM item_lancamento i
--                       WHERE i.ano_lancto = v_ano_lancto
--                         AND i.mes_lancto = v_mes_lancto                 
--                         AND i.cod_rubrica IN (v_rub_agua, v_rub_esgoto, v_rub_esgoto_esp)
--                         AND EXISTS (
--                                SELECT NULL
--                                  FROM lancamento l
--                                 WHERE l.mes_lancto = l.mes_lancto
--                                   AND l.ano_lancto = v_ano_lancto
--                                   AND l.num_aviso = i.num_aviso
--                                   AND l.ano_lancto = i.ano_lancto
--                                   AND l.num_aviso = i.num_aviso)
--                    GROUP BY i.num_aviso,
--                             i.ano_lancto,
--                             i.num_emissao,
--                             i.cod_rubrica,
--                             i.val_parcela
--                      HAVING COUNT (1) > 1
--                ) liga
--        WHERE la.num_aviso = liga.num_aviso
--          AND la.ano_lancto = liga.ano_lancto
--          AND la.num_emissao = liga.num_emissao;
--     
--     EXCEPTION WHEN OTHERS THEN 
--        v_sqlerrm := SQLERRM || ' (TECNICO 011 - VALIDAR ITENS DE FATURA DUPLICADOS (AGUA, ESGOTO OU ESGOTO ESP) !!!';
--     END; 
--     
--     IF v_sqlerrm IS NULL THEN 
--     
--         IF v_count > 0 THEN 
--           
--            v_processo := v_processo || v_separador ||                      
--                          '011 - Inconsistencia: Verificar itens de fatura duplicados (Agua, Esgoto ou Esgoto Esp)! Qtde: ' || v_count;
--            
--         ELSE 
--         
--            v_processo := v_processo || v_separador ||                      
--                          '011 - OK - Nenhuma inconsistencia nos itens das contas (DUPLICIDADE)!';
--         END IF;
--     
--     ELSE 
--        
--         v_processo := v_processo || v_separador || v_sqlerrm;    
--        
--     END IF;
          
     --- VALIDACAO DE NOTA FISCAL DE FATURAMENTO COM VALOR NEGATIVO
     BEGIN 
        
        v_count :=
            executa_comando ('
            SELECT COUNT (*)
              FROM (SELECT num_ligacao
                      FROM nota_fiscal@DB_LINK
                     WHERE ano_lancto = ' || v_ano_lancto || 
                     ' AND mes_lancto = ' || v_mes_lancto || ' AND val_lancto < 0
                    UNION
                    SELECT num_ligacao
                      FROM lancamento@DB_LINK
                     WHERE ano_lancto = ' || v_ano_lancto || 
                     ' AND mes_lancto = ' || v_mes_lancto || ' AND val_lancto < 0 )', I.dblink_cliente 
             
             );
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 060 - VALIDAR NOTA FISCAL DE FATURAMENTO COM VALOR(R$) NEGATIVO !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '060 - Inconsistencia: Existem nota fiscal de faturamento com valor negativo! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '060 - OK - NAO existe inconsistencia de notas lancadas para está referencia: ' || LPAD(v_mes_lancto, 2, '0') || '/' || v_ano_lancto;
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     
     ---- LANCAMENTOS NÃO RETIDOS SEM NOTA FISCAL GERADA ----
     
     v_sqlerrm := NULL;
     v_count   := 0;       
     
     --- VALIDAR PROBLEMA COM BAIXA DE CORTE ----
     BEGIN 
     
         --SELECT C.num_ligacao, C.cod_grupo, C.num_rodada, C.num_corte
        v_count :=
            executa_comando ('
            SELECT COUNT(*)
              FROM cobranca@DB_LINK c, ligacao@DB_LINK l
             WHERE c.zona_ligacao = l.zona_ligacao
               AND c.num_ligacao = l.num_ligacao
               AND l.sit_ligacao IN ( ''C'', ''K'' )
               AND c.cod_fase < 5
               AND c.num_corte =
                      (SELECT MAX (num_corte)
                         FROM cobranca@DB_LINK c1
                        WHERE c1.zona_ligacao = c.zona_ligacao
                          AND c1.num_ligacao = c.num_ligacao)
               AND c.num_rodada =
                        (SELECT MAX (num_rodada)
                           FROM cobranca@DB_LINK c2
                          WHERE c2.num_corte = c.num_corte 
                            AND c2.cod_grupo = c.cod_grupo) ', I.dblink_cliente);
     
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 061 - ERRO NA BAIXA DO CORTE, LIGACAO CORTADA NA FASE ERRADA !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '061 - Inconsistencia: Existem ligações com erro na baixa do corte! Qtde: ' || v_count || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '061 - OK - NAO existe inconsistencia nas baixas de corte.';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;            
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_total_ligacao :=
           executa_comando ('
                SELECT COUNT(*)
                  FROM ligacao@DB_LINK 
                 WHERE sit_ligacao IN (''A'', ''C'', ''K'') ', I.dblink_cliente);
        
        v_total_leituras :=
           executa_comando ('
                SELECT COUNT(*)
                  FROM leitura@DB_LINK 
                 WHERE ano_lancto = ' || v_ano_lancto ||
                 ' AND mes_lancto = ' || v_mes_lancto, I.dblink_cliente); 
         
        --SELECT num_ligacao, dsc_simultanea, sta_emitido, cod_grupo
        v_count := 
           executa_comando ('
                 SELECT COUNT(*)
                   FROM lancamento@DB_LINK 
                  WHERE ano_lancto = ' || v_ano_lancto ||
                  ' AND mes_lancto = ' || v_mes_lancto ||
                  ' AND num_nota = 0', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 065 - QUANTIFICAR N.F.C. (LANCAMENTO) NÃO FATURADAS !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador ||                     
                          '065 - AVISO: Existe(m) ' || v_count || ' N.F.C. não faturas de um total de ' || v_total_leituras 
                                                    || ' leituras agendadas. ( TOTAL LIG = ' || v_total_ligacao || ' )' ;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '065 - OK - Todas as N.F.C. foram faturadas para está referencia: ' || LPAD(v_mes_lancto, 2, '0') || '/' || v_ano_lancto;
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                SELECT COUNT(*)
                  FROM leitura@DB_LINK
                 WHERE ano_lancto = ' || v_ano_lancto ||
                 ' AND mes_lancto = ' || v_mes_lancto ||
                 ' AND cod_leitura_int = ' || LEIT_NAO_REALIZADA, I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 070 - QUANTIFICAR LEITURAS A REALIZAR !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador ||                      
                          '070 - AVISO: Existe(m) ' || v_count || ' LEITURA(S) não realizada(s) de um total de ' || v_total_leituras 
                                                    || ' leituras agendadas ( TOTAL LIG = ' || v_total_ligacao || ' )';
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '070 - OK - Todas as LEITURAS foram realizadas para está referencia: ' || LPAD(v_mes_lancto, 2, '0') || '/' || v_ano_lancto;
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                    FROM slip@DB_LINK s
                         JOIN
                            aviso_credito@DB_LINK a
                         ON (a.num_aviscred = s.num_aviscred
                             AND a.ano_aviscred = s.ano_aviscred)
                   WHERE TRIM (tpo_arrecad) IS NULL ', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 075 - RELACAO POR TIPO DE ARRECADACAO !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '075 - AVISO: Existe(m) ' || v_count || ' slip(s) sem classificação da origem do pagamento (Guiche, Internet e etc.).' ||  tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '075 - OK - Todos os registros de pagamentos contém classificação da origem do pagamento.';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                    FROM nota_fiscal@DB_LINK s
                   WHERE LENGTH( dat_evento ) < 8 OR LENGTH( dat_emissao ) < 8', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 080 - INCONSISTENCIA CAMPOS DATA NOTA FISCAL !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '080 - AVISO: Existe(m) ' || v_count || ' notas(s) com inconsistencia nos campo DAT_EMISSAO e DAT_EVENTO' ||  tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '080 - OK - Todos os registros da nota fiscal estao validos (DAT_EMISSAO e DAT_EVENTO).';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                    FROM nota_fiscal@DB_LINK
                   WHERE dat_emissao > dat_evento ', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 081 - DIVERGENCIA EM DATAS DE EVENTOS CONTABEIS - NOTA FISCAL !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '081 - AVISO: Existe(m) ' || v_count || ' notas(s) com divergencia em datas (DAT_EMISSAO > DAT_EVENTO)' ||  tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '081 - OK - Todos os registros da nota fiscal estao validos (DAT_EMISSAO > DAT_EVENTO).';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
          
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                    FROM nota_fiscal@DB_LINK
                   WHERE SUBSTR (dat_emissao, 1, 6) > ano_lancto || LPAD (mes_lancto, 2, ''0'')
                     AND num_nota = num_nota_orig
                     AND ano_lancto || LPAD (mes_lancto, 2, ''0'') > 201409 ', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 082 - DIVERGENCIA EM DATAS DE EVENTOS CONTABEIS - DAT_EMISSAO > MES ANO REF !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '082 - AVISO: Existe(m) ' || v_count || ' notas(s) com divergencia em datas (DAT_EMISSAO > MES ANO REF)' || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '082 - OK - Todos os registros da nota fiscal estao validos (DAT_EMISSAO > MES ANO REF).';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
          
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                    FROM vew_lancamentos@DB_LINK
                   WHERE TO_CHAR( dat_vencto, ''YYYY'') < 1000 ', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 090 - INCONSISTENCIA CAMPOS DATA VEW_LANCAMENTOS !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '090 - AVISO: Existe(m) ' || v_count || ' lancamentos(s) com inconsistencia nos campo DAT_VENCTO' ||  tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '090 - OK - Todos os registros de lancamentos estao validos (DAT_VENCTO).';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                      FROM (  SELECT cc_next_value prox_numero_aviso, SUBSTR (cc_domain, 9, 4) ano, cc_domain
                                FROM cg_code_controls@DB_LINK
                               WHERE (cc_domain LIKE ''SQ_AVISO201%''
                                      OR cc_domain LIKE ''SQ_AVISO202%'')
                            ORDER BY TO_NUMBER (SUBSTR (cc_domain, 9, 4))) N,
                           (  SELECT MAX (num_aviso) max_aviso, ano_lancto
                                FROM parcela@DB_LINK
                            GROUP BY ano_lancto) p
                     WHERE p.ano_lancto = n.ano 
                       AND p.max_aviso > n.prox_numero_aviso ', I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 100 - INCONSISTENCIA NO CONTROLE DE NUMERADORES (NUMERO AVISO) !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '100 - AVISO: Existe(m) ' || v_count || ' numeradores com divergencia (SQ_AVISO201%).' ||  tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '100 - OK - Todos os numeradores estao na sequencia correta.';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
     v_sqlerrm := NULL;
     v_count   := 0; 
        
     BEGIN 
        
        v_count := 
           executa_comando ('
                  SELECT COUNT (*)
                    FROM lancamento_pag@DB_LINK 
                   WHERE cod_tributo = 1 AND num_nota = 0 
                     AND mes_lancto = ' || v_mes_lancto || 
                   ' AND ano_lancto = ' || v_ano_lancto, I.dblink_cliente);
     
     EXCEPTION WHEN OTHERS THEN 
        v_sqlerrm := SQLERRM || ' (TECNICO 110 - INCONSISTENCIA NO REGISTRO QUITADO SEM NOTA FISCAL !!!';
     END; 
     
     IF v_sqlerrm IS NULL THEN 
     
         IF v_count > 0 THEN 
           
            v_processo := v_processo || v_separador || tag_h3 ||                      
                          '110 - AVISO: Existe(m) ' || v_count || ' lancamentos quitados sem nota fiscal !!!' || tagf_h3;
            
         ELSE 
         
            v_processo := v_processo || v_separador ||                      
                          '110 - OK - Todos os lançamentos quitados estão com nota fiscal registrada.';
         END IF;
     
     ELSE 
        
         v_processo := v_processo || v_separador || v_sqlerrm;    
        
     END IF;
     
          
     --- CALCULAR TEMPO DE PROCESSAMENTO ---
     v_dt_fim := SYSDATE;
     
     v_processo := v_processo || v_separador ||
                   'Fim do processamento em ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI') || CHR(10) ||
                   tag_p ||
                   'Tempo (minutos) ' || TO_CHAR( ROUND( ( (v_dt_fim - v_dt_ini) * 24 ) * 60, 2) ) || CHR(10) || CHR(10) ||
                   '</body>' || CHR(10) ||
                   '</html>';                                

--     send_mail2(p_assunto => 'VALIDAÇÃO BASE DE DADOS: ' || UPPER( I.ds_contrato ), 
--                p_mensagem => v_processo);
                
--         FOR j IN ( select 'douglas.dasilva@gssbr.com.br' email from dual union 
--                    select 'alessandra.requejo@gssbr.com.br' email from dual ) 
--                    
--                    LOOP 
                  
                 ErrorStatus := PKG_SEND_EMAIL.SendMail@portalgmf(
                            p_sq_contrato => 10,
                            Sender    => null,
                            Recipient => 'douglas.dasilva@gssbr.com.br' ,                                                          
                            CcRecipient => 'alessandra.requejo@gssbr.com.br', 
--                            ,'alessandra.requejo@gssbr.com.br'
                            BccRecipient => null,
                            Subject   => 'VALIDAÇÃO BASE DE DADOS: ' || UPPER( I.ds_contrato ),
                            Type_provider => 'E',
                            Body => v_processo,
                            ErrorMessage => ErrorMessage1,
                            Attachments  => null
                                 );
                 
    --     dbms_OUTput.put_line(v_processo) ;
            
                    v_processo := NULL;
--                    ErrorMessage1 := NULL;
                    
--         END LOOP;                     
     
     END LOOP;     

END;
/
