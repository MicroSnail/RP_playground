`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2017 11:54:36 AM
// Design Name: 
// Module Name: processing_system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module processing_system(
	inout [14:0]DDR_addr			,
	inout [2:0]DDR_ba					,
	inout DDR_cas_n						,
	inout DDR_ck_n						,
	inout DDR_ck_p						,
	inout DDR_cke							,
	inout DDR_cs_n						,
	inout [3:0]DDR_dm					,
	inout [31:0]DDR_dq				,
	inout [3:0]DDR_dqs_n			,
	inout [3:0]DDR_dqs_p			,
	inout DDR_odt							,
	inout DDR_ras_n						,
	inout DDR_reset_n					,
	inout DDR_we_n						,
	inout FIXED_IO_ddr_vrn		,
	inout FIXED_IO_ddr_vrp		,
	inout [53:0]FIXED_IO_mio	,
	inout FIXED_IO_ps_clk			,
	inout FIXED_IO_ps_porb		,
	inout FIXED_IO_ps_srstb		,
	input clk_125							,
	sys_bus_if bus
    );

axi4_if #(.DW (32), .AW (32), .IW (12), .LW (4)) 
				axi_gp (.ACLK (bus.clk), .ARESETn (bus.rstn));

axi4_slave #(
  .DW (32),
  .AW (32),
  .IW (12)
) axi_slave_gp0 (
  // AXI bus
  .axi       (axi_gp),
  // system read/write channel
  .bus       (bus)
);

zynq_block_wrapper zynqchip(
    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
    .M_AXI_GP0_ACLK(clk_125),
  	.M_AXI_GP0_arvalid (axi_gp.ARVALID),
  	.M_AXI_GP0_awvalid (axi_gp.AWVALID),
  	.M_AXI_GP0_bready  (axi_gp.BREADY ),
  	.M_AXI_GP0_rready  (axi_gp.RREADY ),
  	.M_AXI_GP0_wlast   (axi_gp.WLAST  ),
  	.M_AXI_GP0_wvalid  (axi_gp.WVALID ),
  	.M_AXI_GP0_arid    (axi_gp.ARID   ),
  	.M_AXI_GP0_awid    (axi_gp.AWID   ),
  	.M_AXI_GP0_wid     (axi_gp.WID    ),
  	.M_AXI_GP0_arburst (axi_gp.ARBURST),
  	.M_AXI_GP0_arlock  (axi_gp.ARLOCK ),
  	.M_AXI_GP0_arsize  (axi_gp.ARSIZE ),
  	.M_AXI_GP0_awburst (axi_gp.AWBURST),
  	.M_AXI_GP0_awlock  (axi_gp.AWLOCK ),
  	.M_AXI_GP0_awsize  (axi_gp.AWSIZE ),
  	.M_AXI_GP0_arprot  (axi_gp.ARPROT ),
  	.M_AXI_GP0_awprot  (axi_gp.AWPROT ),
  	.M_AXI_GP0_araddr  (axi_gp.ARADDR ),
  	.M_AXI_GP0_awaddr  (axi_gp.AWADDR ),
  	.M_AXI_GP0_wdata   (axi_gp.WDATA  ),
  	.M_AXI_GP0_arcache (axi_gp.ARCACHE),
  	.M_AXI_GP0_arlen   (axi_gp.ARLEN  ),
  	.M_AXI_GP0_arqos   (axi_gp.ARQOS  ),
  	.M_AXI_GP0_awcache (axi_gp.AWCACHE),
  	.M_AXI_GP0_awlen   (axi_gp.AWLEN  ),
  	.M_AXI_GP0_awqos   (axi_gp.AWQOS  ),
  	.M_AXI_GP0_wstrb   (axi_gp.WSTRB  ),
  	.M_AXI_GP0_arready (axi_gp.ARREADY),
  	.M_AXI_GP0_awready (axi_gp.AWREADY),
  	.M_AXI_GP0_bvalid  (axi_gp.BVALID ),
  	.M_AXI_GP0_rlast   (axi_gp.RLAST  ),
  	.M_AXI_GP0_rvalid  (axi_gp.RVALID ),
  	.M_AXI_GP0_wready  (axi_gp.WREADY ),
  	.M_AXI_GP0_bid     (axi_gp.BID    ),
  	.M_AXI_GP0_rid     (axi_gp.RID    ),
  	.M_AXI_GP0_bresp   (axi_gp.BRESP  ),
  	.M_AXI_GP0_rresp   (axi_gp.RRESP  ),
  	.M_AXI_GP0_rdata   (axi_gp.RDATA  )
  );

endmodule
