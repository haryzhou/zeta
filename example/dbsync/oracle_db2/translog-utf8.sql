-- Create table
create table TRANSLOG
(
  sys_date        CHAR(8) not null,
  sys_time        CHAR(6),
  busitype        CHAR(4),
  busioper        CHAR(1),
  apptype         CHAR(4),
  psam            CHAR(16),
  fwd_ins_id_cd   CHAR(8) not null,
  rcv_ins_id_cd   CHAR(8),
  fld32_ins_id_cd CHAR(8),
  loc_trans_tm    CHAR(6),
  loc_trans_dt    CHAR(4) not null,
  card_attr       CHAR(2),
  iss_ins_id_cd   CHAR(8),
  outpan          CHAR(30),
  name            VARCHAR(70),
  licensetype     CHAR(2),
  license         CHAR(20),
  inpan           CHAR(30),
  amount          CHAR(12),
  payamount       CHAR(12),
  settledate      CHAR(4),
  pos_entry_md_cd CHAR(3),
  pos_cond_cd     CHAR(2),
  auth_id_resp_cd CHAR(6),
  trans_curr_cd   CHAR(3),
  ordernumber     CHAR(30),
  entrymsgid      CHAR(4),
  entryproccode   CHAR(6),
  entrychannele   CHAR(4),
  entryfoldid     CHAR(10),
  entryseqno      CHAR(6) not null,
  entryshopid     CHAR(15) not null,
  entrytermid     CHAR(8) not null,
  appmsgid        CHAR(4),
  appproccode     CHAR(6),
  appchannele     CHAR(4),
  appfoldid       CHAR(10),
  appseqno        CHAR(6),
  apprefnbr       CHAR(12),
  appshopid       CHAR(15),
  apptermid       CHAR(8),
  appretcode      CHAR(6),
  centerretcode   CHAR(2),
  busiflag        CHAR(1),
  voidflag        CHAR(1),
  settleflag      CHAR(1),
  addidata1       VARCHAR(100),
  addidata2       VARCHAR(200),
  area            CHAR(6),
  tel             CHAR(12),
  paymsgid        CHAR(4),
  payproccode     CHAR(6),
  paychannele     CHAR(4),
  payfoldid       CHAR(10),
  payseqno        CHAR(6),
  payrefnbr       CHAR(12),
  payshopid       CHAR(15),
  paytermid       CHAR(8),
  payretcode      CHAR(6),
  app_ins_id_cd   CHAR(8),
  timestamp       CHAR(14)
);

-- Add comments to the columns 
comment on column TRANSLOG.sys_date is '交易日期';
comment on column TRANSLOG.sys_time is '交易时间 ';
comment on column TRANSLOG.busitype is '业务类型';
comment on column TRANSLOG.busioper is '业务操作方向';
comment on column TRANSLOG.apptype is '交易类型';
comment on column TRANSLOG.psam is 'Psam卡号';
comment on column TRANSLOG.fwd_ins_id_cd is '交易上送机构号★';
comment on column TRANSLOG.rcv_ins_id_cd is '渠道机构号';
comment on column TRANSLOG.fld32_ins_id_cd is '受理机构号';
comment on column TRANSLOG.loc_trans_tm is '上送交易时间★';
comment on column TRANSLOG.loc_trans_dt is '上送交易日期';
comment on column TRANSLOG.card_attr is '卡属性';
comment on column TRANSLOG.iss_ins_id_cd is '发卡行代码';
comment on column TRANSLOG.outpan is '转出账户';
comment on column TRANSLOG.name is '户名';
comment on column TRANSLOG.licensetype is '证件类型';
comment on column TRANSLOG.license is '证件号码';
comment on column TRANSLOG.inpan is '转入账户';
comment on column TRANSLOG.amount is '交易金额';
comment on column TRANSLOG.payamount is '手续费';
comment on column TRANSLOG.settledate is '清算日期';
comment on column TRANSLOG.pos_entry_md_cd is '服务点输入方式码';
comment on column TRANSLOG.pos_cond_cd is '服务点条件码';
comment on column TRANSLOG.auth_id_resp_cd is '授权码';
comment on column TRANSLOG.trans_curr_cd is '交易币种';
comment on column TRANSLOG.ordernumber is '订单号（适用电力客户号等）';
comment on column TRANSLOG.entrymsgid is '进入通道报文头';
comment on column TRANSLOG.entryproccode is '进入通道处理码';
comment on column TRANSLOG.entrychannele is '进入通道类型';
comment on column TRANSLOG.entryfoldid is '进入通道fold ID';
comment on column TRANSLOG.entryseqno is '进入通道流水号★';
comment on column TRANSLOG.entryshopid is '进入通道商户号';
comment on column TRANSLOG.entrytermid is '进入通道终端号';
comment on column TRANSLOG.appmsgid is '渠道方通道报文头';
comment on column TRANSLOG.appproccode is '渠道方通道处理码';
comment on column TRANSLOG.appchannele is '渠道方通道类型';
comment on column TRANSLOG.appfoldid is '渠道方通道fold ID';
comment on column TRANSLOG.appseqno is '渠道方通道流水号';
comment on column TRANSLOG.apprefnbr is '渠道方通道系统参考号';
comment on column TRANSLOG.appshopid is '渠道方通道商户号';
comment on column TRANSLOG.apptermid is '渠道方通道终端号';
comment on column TRANSLOG.appretcode is '渠道方通道应答码';
comment on column TRANSLOG.centerretcode is '中心应答码';
comment on column TRANSLOG.busiflag is '业务状态标识';
comment on column TRANSLOG.voidflag is '冲正标识';
comment on column TRANSLOG.settleflag is '清算标识';
comment on column TRANSLOG.addidata1 is '业务附加数据1';
comment on column TRANSLOG.addidata2 is '业务附加数据2';
comment on column TRANSLOG.area is '区号';
comment on column TRANSLOG.tel is '电话号码';
comment on column TRANSLOG.paymsgid is '扣款方通道报文头';
comment on column TRANSLOG.payproccode is '扣款方通道处理码';
comment on column TRANSLOG.paychannele is '扣款方通道类型';
comment on column TRANSLOG.payfoldid is '扣款方通道fold ID';
comment on column TRANSLOG.payseqno is 'xxx';
comment on column TRANSLOG.payrefnbr is '扣款方通道系统参考号';
comment on column TRANSLOG.payshopid is '扣款方通道商户号';
comment on column TRANSLOG.paytermid is '扣款方通道终端号';
comment on column TRANSLOG.payretcode is '扣款方通道应答码';
comment on column TRANSLOG.app_ins_id_cd is '银行代码';
comment on column TRANSLOG.timestamp is '时间戳';
