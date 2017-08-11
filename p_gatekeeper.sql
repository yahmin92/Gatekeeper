set serveroutput on;

declare

  TYPE gk_case is table of GK_CASE_SUBS%rowtype index by pls_integer;
  v_price_plan varchar2(100);
  v_soc_pp varchar2(10);

gk gk_case;

  CURSOR cgk is 
    select * from gk_subscriber
    where trunc(sys_creation_date) >= trunc(sysdate -1)
    and rownum <= 5;

  PROCEDURE GET_PRICE_PLAN(p_sub in number,p_soc out varchar2, p_soc_name out varchar2) IS
  BEGIN
    begin
      select sa.soc, co.soc_name
      into p_soc, p_soc_name
      from service_agreement@xlcm1VAD sa join csm_offer@xlcm1VAD co on co.soc_cd = sa.soc
      and sa.agreement_no = p_sub
      and sa.expiration_date is null
      and co.soc_type = 'P';
    exception 
      when no_data_found then
        dbms_output.put_line(SQLERRM);
    end;
  END;
  
  FUNCTION getCreditLimitAndType(p_ben IN NUMBER, p_type out VARCHAR2, p_crdLimit out float,
    op_id out NUMBER) RETURN BOOLEAN IS
    retval boolean := true;
  BEGIN
    BEGIN
      SELECT l9_credit_limit,trim(L9_CREDIT_LIMIT_TYPE),
      INTO p_crdLimit, p_type
      FROM csm_ben@xlcm1vad
      WHERE ben = p_ben;
    exception
      WHEN no_data_found THEN
        dbms_output.put_line('BEN '||p_ben||' not found in CSM_BEN');
    END;
    dbms_output.put_line('Inner '||p_type||' ben '||p_ben);
    return retval;
  END;

  FUNCTION getAddress(p_ben in number) RETURN BOOLEAN IS
    retval boolean := true;
  BEGIN
    BEGIN
      select ad.adr_elem14 into p_email
      from address_name_link@xlcm1vad adl 
      join address_data@xlcm1vad ad on adl.address_id = ad.address_id
      and adl.entity_id = p_ben
      and adl.link_type = 'B'
      and adl.expiration_date is null;
    exception
      when no_data_found THEN
        retval := false;
    END;
    RETURN retval;
  END;
  
  PROCEDURE PROCESS_BEN(p_ben in number, p_case in varchar2) IS
    v_crd_limit_type varchar2(5);
    v_crd_limit float;
  BEGIN
    IF getCreditLimitAndType(p_ben,v_crd_limit_type, v_crd_limit) THEN
      --evaluate
      IF v_crd_limit_type = 'PACT' then
        REGISTER_CASE('Case id', gk);
      END IF;

      IF v_crd_limit = 0 THEN
        REGISTER_CASE('case id', gk);
      END IF;      
    END IF;

    --cek email address
    IF getAddress(p_ben) THEN
      
    END IF;

  END; --PROCESS_BEN
  
--MAIN PROC
BEGIN

  FOR cg in cgk LOOP
    
    GET_PRICE_PLAN(CG.SUBSCRIBER_NO, v_soc_pp, v_price_plan);
    dbms_output.put_line(cg.msisdn||' '||v_price_plan);
    PROCESS_BEN;
  END LOOP;
END;