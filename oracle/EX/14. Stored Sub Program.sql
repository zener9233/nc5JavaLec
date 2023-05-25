--1. STORED PROCEDURE
--1-1. 파라미터가 없는 프로시저
--프로시저 선언
CREATE OR REPLACE PROCEDURE PRO_NOPARAM
IS
    ENO VARCHAR2(8);
    ENAME VARCHAR2(20);
BEGIN
    ENO := '9999';
    ENAME := '장길산';
    
    INSERT INTO EMP(ENO, ENAME)
    VALUES(ENO, ENAME);
END;
/

--프로시저 실행
EXEC PRO_NOPARAM;

SELECT *
    FROM EMP
    WHERE ENO = '9999';

--일반화학의 학생별 기말고사 성적을 저장하는 테이블 생성
CREATE TABLE T_NCHE_SC1
AS SELECT SC.*, ST.SNAME 
      FROM SCORE SC 
      JOIN COURSE C
      ON SC.CNO = C.CNO
      RIGHT JOIN STUDENT ST
      ON SC.SNO = ST.SNO
      WHERE C.CNAME = '일반화학1';

DROP TABLE T_NCHE_SC1;
SELECT *
    FROM T_NCHE_SC1;

--GRADE까지 가지는 일반화학 학생별 기말고사 성적 테이블
CREATE TABLE T_NCHE_SCGR1(
    SNO NUMBER PRIMARY KEY,
    SNAME VARCHAR2(20),
    RESULT NUMBER(5, 2),
    GRADE CHAR(1)
);

SELECT *
    FROM T_NCHE_SCGR1;

--T_NCHE_SC1을 참조해서 T_NCHE_SCGR1에 데이터를 저장하는
--프로시저 선언
CREATE OR REPLACE PROCEDURE P_NCHE_SCGR
IS
    --레코드
    TYPE NCHE_SCGR_REC IS RECORD(
        SNO T_NCHE_SCGR1.SNO%TYPE,
        SNAME T_NCHE_SCGR1.SNAME%TYPE,
        RESULT T_NCHE_SCGR1.RESULT%TYPE,
        GRADE T_NCHE_SCGR1.GRADE%TYPE
    );
    --레코드변수 선언
    NCHESCGRREC NCHE_SCGR_REC;
    
    --커서(쿼리의 결과를 저장하는 자료형)
    CURSOR CUR_NCHE_SCGR IS
    SELECT NCS.SNO
         , NCS.SNAME
         , NCS.RESULT
         , 'A'
        FROM T_NCHE_SC1 NCS;
BEGIN
    --커서 오픈
    OPEN CUR_NCHE_SCGR;
    --루프
    LOOP
        --패치
        FETCH CUR_NCHE_SCGR INTO NCHESCGRREC;
        
        EXIT WHEN CUR_NCHE_SCGR%NOTFOUND;
        
        --점수별 등급 조건문(IF THEN~ELSIF THEN~ELSE)
        IF NCHESCGRREC.RESULT >= 90 THEN
            NCHESCGRREC.GRADE := 'A';
        ELSIF NCHESCGRREC.RESULT >= 80 THEN
            NCHESCGRREC.GRADE := 'B';
        ELSIF NCHESCGRREC.RESULT >= 70 THEN
            NCHESCGRREC.GRADE := 'C';
        ELSIF NCHESCGRREC.RESULT >= 60 THEN
            NCHESCGRREC.GRADE := 'D';
        ELSE NCHESCGRREC.GRADE := 'F';
        END IF;
        
        --인서트문
        INSERT INTO T_NCHE_SCGR1
        VALUES NCHESCGRREC;
        
    --루프끝
    END LOOP;
    --커서 클로즈
    CLOSE CUR_NCHE_SCGR;
END;
/

EXEC P_NCHE_SCGR;

SELECT *
    FROM T_NCHE_SCGR1;
    
--1-2. 파라미터가 있는 프로시저
CREATE OR REPLACE PROCEDURE P_NEW_DEPT1
(
    DNO IN VARCHAR2,
    DNAME IN VARCHAR2,
    LOC IN VARCHAR2,
    DIRECTOR IN VARCHAR2 DEFAULT '1111'
)
IS

BEGIN
    INSERT INTO DEPT
    VALUES (
        DNO,
        DNAME,
        LOC,
        DIRECTOR
    );
END;
/

--프로시저 호출 시 파라미터 전달
EXEC P_NEW_DEPT1('98', '테스트', '대전', '2001');

SELECT * FROM DEPT;

--2. Stored Function
--급여별로 세금 조회하는 함수선언
CREATE OR REPLACE FUNCTION F_GETTAX1
(
    SAL NUMBER
)
RETURN NUMBER
IS
    TAX NUMBER;
BEGIN
    IF SAL >= 7000 THEN TAX := 0.1;
    ELSIF SAL >= 6000 THEN TAX := 0.07;
    ELSIF SAL >= 5000 THEN TAX := 0.05;
    ELSE TAX := 0.03;
    END IF;
    
    RETURN ROUND(SAL * TAX);
END;
/

--F_GETTAX 함수 쿼리문에서 호출
SELECT E.*
     , F_GETTAX1(E.SAL) AS TAX
    FROM EMP E;

--3. TRIGGER
--3-1. BEFORE TRIGGER
--급여가 3000미만으로 입력됐을 때 
--에러메시지 출력하는 트리거
CREATE OR REPLACE TRIGGER TR_EMP_SAL1
BEFORE
INSERT OR UPDATE OF SAL ON EMP
REFERENCING NEW AS NEW
FOR EACH ROW
BEGIN
    IF :NEW.SAL < 3000 THEN
        IF INSERTING THEN
            RAISE_APPLICATION_ERROR(-20000, 
            '최저급여보다 낮음');
        ELSIF UPDATING THEN
            RAISE_APPLICATION_ERROR(-20001, 
            '최저급여보다 낮음');
        ELSE
            RAISE_APPLICATION_ERROR(-20002, 
            '최저급여보다 낮음');
        END IF;
    END IF;
END;
/

INSERT INTO EMP
VALUES(
    '8001', 
    '홍길동', 
    '취합',
    '2001',
    SYSDATE, 
    3100, 
    0, 
    '01');

SELECT *
    FROM EMP;

UPDATE EMP
    SET
        SAL = 3200
    WHERE ENO = '9999';

--3-2. AFTER TRIGGER
--T_NCHE_SC 테이블에 데이터가 입력이나 점수가 수정되면
--T_NCHE_SCGR 테이블에 데이터가 자동으로 입력되거나
--점수가 수정된 거는 GRADE가 자동 업데이트되는 트리거
CREATE OR REPLACE TRIGGER TR_NCHE_SCGR1
AFTER
INSERT OR UPDATE ON T_NCHE_SC1
REFERENCING NEW AS NEW
FOR EACH ROW
DECLARE
    GRD CHAR(1);
BEGIN
    IF :NEW.RESULT >=90 THEN GRD := 'A';
    ELSIF :NEW.RESULT >= 80 THEN GRD := 'B';
    ELSIF :NEW.RESULT >= 70 THEN GRD := 'C';
    ELSIF :NEW.RESULT >= 60 THEN GRD := 'D';
    ELSE GRD := 'F';
    END IF;
    
    MERGE INTO T_NCHE_SCGR1 A
    USING DUAL
    ON (A.SNO = :NEW.SNO)
    WHEN MATCHED THEN 
        UPDATE
            SET
                A.RESULT = :NEW.RESULT,
                A.GRADE = GRD
    WHEN NOT MATCHED THEN
        INSERT (A.SNO, A.SNAME, A.RESULT, A.GRADE)
        VALUES (:NEW.SNO, :NEW.SNAME, :NEW.RESULT, GRD);
END;
/

DROP TRIGGER TR_NCHE_SCGR1;

INSERT INTO T_NCHE_SC1
VALUES (8002, 1211, 94, '고기천');

SELECT *
    FROM T_NCHE_SCGR1
    WHERE SNO = 915305;

UPDATE T_NCHE_SC1
    SET
        RESULT = 65
    WHERE SNO = 915305;

