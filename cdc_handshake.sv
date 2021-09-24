module cdc_handshake #(
  parameter CDC_REG_AMOUNT    = 2,
  parameter PASS_IMMEDIATELY  = 0
)(
  input   rst_m_i,
  input   rst_s_i,

  input   clk_m_i,
  input   clk_s_i,

  input   m_req_i,
  output  m_ack_o,

  input   s_ack_i,
  output  s_req_o
);

logic [CDC_REG_AMOUNT:0]  m_ack_sync_reg;
logic [CDC_REG_AMOUNT:0]  s_req_sync_reg;

logic m_wait;
logic m_wait_set;
logic m_wait_clear;

logic s_req;
logic s_req_set;
logic s_req_clear;

logic m_req;
logic m_req_set;
logic m_req_clear;

logic s_ack;
logic s_ack_set;
logic s_ack_clear;

logic m_req_toggle;
logic s_ack_toggle;

logic m_ack_posedge_stb, m_ack_negedge_stb;
logic s_req_posedge_stb, s_req_negedge_stb;

logic m_ack_stb;
logic s_req_stb;

logic m_req_cross_domain;
logic s_ack_cross_domain;

//**************************************************
// Master clock domain
//**************************************************

// master request register toggling
always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_req <= 1'b0;
  else
    if( m_req_toggle )
      m_req <= ~m_req;

// prevent toggling when request in process
always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_wait <= 1'b0;
  else
    if( m_wait_set )
      m_wait <= 1'b1;
    else
      if( m_wait_clear )
        m_wait <= 1'b0;

assign m_req_toggle = m_req_i && ~m_wait;

assign m_wait_set   = m_req_toggle;
assign m_wait_clear = m_ack_stb;

//**************************************************
// Slave clock domain
//**************************************************

always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_ack <= 1'b0;
  else
    if( s_ack_toggle )
      s_ack <= ~s_ack;

always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_req <= 1'b0;
  else
    if( s_req_set )
      s_req <= 1'b1;
    else
      if( s_req_clear )
        s_req <= 1'b0;

assign s_ack_toggle = s_req && s_ack_i;

assign s_req_set    = s_req_stb;
assign s_req_clear  = s_ack_toggle;

//********************************************
// Cross domain sync registers
//********************************************

// cross clock domain sync registers
always_ff @( posedge clk_s_i, posedge rst_s_i )
  if( rst_s_i )
    s_req_sync_reg <= '0;
  else
    s_req_sync_reg <= { s_req_sync_reg[CDC_REG_AMOUNT-1:0], m_req_cross_domain };

always_ff @( posedge clk_m_i, posedge rst_m_i )
  if( rst_m_i )
    m_ack_sync_reg <= '0;
  else
    m_ack_sync_reg <= { m_ack_sync_reg[CDC_REG_AMOUNT-1:0], s_ack_cross_domain };

//********************************************
// Output assigns
//********************************************

assign s_req_posedge_stb = ~s_req_sync_reg[CDC_REG_AMOUNT]   && s_req_sync_reg[CDC_REG_AMOUNT-1];
assign s_req_negedge_stb = ~s_req_sync_reg[CDC_REG_AMOUNT-1] && s_req_sync_reg[CDC_REG_AMOUNT];

assign m_ack_posedge_stb = ~m_ack_sync_reg[CDC_REG_AMOUNT]   && m_ack_sync_reg[CDC_REG_AMOUNT-1];
assign m_ack_negedge_stb = ~m_ack_sync_reg[CDC_REG_AMOUNT-1] && m_ack_sync_reg[CDC_REG_AMOUNT];

// This means that real request will get to cross-domain pipe with 1 tick
// delay, so as acknowledge. And if need, request and ack can be passed
// directly to cross-domain pipe as soon as it get to module
generate
  if( PASS_IMMEDIATELY )
    begin

      assign m_req_cross_domain = m_req || m_req_toggle;
      assign s_ack_cross_domain = s_ack || s_ack_toggle;

    end
  else
    begin

      assign m_req_cross_domain = m_req;
      assign s_ack_cross_domain = s_ack;

    end
endgenerate

assign s_req_stb = s_req_posedge_stb || s_req_negedge_stb;
assign m_ack_stb = m_ack_posedge_stb || m_ack_negedge_stb;

assign s_req_o = s_req;
assign m_ack_o = m_ack_stb;

endmodule : cdc_handshake

