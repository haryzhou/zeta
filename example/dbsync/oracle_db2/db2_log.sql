drop table db2_log;
create table db2_log(
    sdate      date,
    ssn        char(6),
    ssn_org    char(6),
    rev_flag   char(1),
    resp_code  char(2),
    tdt        char(19),
    acq_id     char(12),
    snd_id     char(12),    
    rcv_id     char(12),
    mid        char(15),
    tid        char(8),
    refnum     char(12),
    authnum    char(12),
    tamt       bigint,
    cno        char(20),
    ctype      char(2),
    ts_u       timestamp
);
create unique index idx_db2_log on db2_log(tdt, ssn);
--  sdate      - 清算日期
--  ssn        - 流水号
--  ssn_org    - 原交易流水号
--  rev_flag   - 冲正标志
--  resp_code  - 应答码
--  tdt        - 交易日期时间
--  acq_id     - 受理机构ID
--  snd_id     - 发送机构ID
--  rcv_id     - 接收机构ID
--  mid        - 商户号
--  tid        - 终端号
--  refnum     - 检索参考号码
--  authnum    - 授权号
--  tamt       - 交易金额
--  cno        - 卡号
--  ctype      - 卡类型


