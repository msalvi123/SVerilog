//Fifo with read out of a flop, read mux hidden behind a head entry,
//All entries write into the head entry.
module flp_fif #(
		     parameter DATA_WIDTH   = 5,
		     parameter DEPTH = 8,
		     parameter ADDR_WIDTH   = $clog2(DEPTH))
   (
     output logic [ADDR_WIDTH:0]   cnt,
     output logic [DATA_WIDTH-1:0] data_out,

    input [DATA_WIDTH-1:0]  data_in,
    input 		    psh,
    input 		    pop,

    input 		    clk,
    input 		    rst_n
   );
   
   logic [ADDR_WIDTH-1:0]   rd_ptr;
   logic [ADDR_WIDTH-1:0]   wr_ptr;
   
   logic [DEPTH-1:0][DATA_WIDTH-1:0] mem;
   logic [DEPTH-1:0] 		     wr_clk_en;
   logic [DATA_WIDTH-1:0] 	     rd_mx_dat;
   logic [ADDR_WIDTH:0] 	     nxt_cnt;
   logic 			     in_sel;
   
   assign nxt_cnt     =  cnt + psh - pop; 
   
   always_ff @ (posedge clk) begin
      cnt <= ~rst_n ? '0 : nxt_cnt;
   end
   
   always_ff @ (posedge clk) begin
      if((cnt < 1) || ((cnt == 1) && psh && pop) || ~rst_n)
	wr_ptr <= 'b1;
      else if((wr_ptr == (DEPTH - 1) && psh))
	wr_ptr <= 'b1;
      else if(psh)
	wr_ptr <= wr_ptr + 1'b1;
   end

   always_ff @ (posedge clk) begin
      if((cnt < 1) || ((cnt == 1) && psh && pop) || ~rst_n)
	rd_ptr <= 'b1;
      else if((rd_ptr == (DEPTH - 1)) && pop) 
	rd_ptr <= 'b1;
      else if(pop)
	rd_ptr <= rd_ptr + 1'b1;
   end

   //Psh wr data in the head entry when cnt=0 OR when cnt=1 and psh and pop happen in the same cycle.
   always_comb begin
      in_sel            = (cnt == 0 & psh) | (cnt == 1) & psh & pop;
      rd_mx_dat         =  mem[rd_ptr];
      
      wr_clk_en         = '0;
      wr_clk_en[wr_ptr] =  psh;
      wr_clk_en[0]      =  in_sel | pop;
   end

   always_ff @ (posedge clk) begin
      for(int i = 1; i < DEPTH ; i = i + 1)
	if(wr_clk_en[i])
      mem[i] <= data_in;
      
      //head entry gets written by input data when fif empty or about to go empty when psh & pop happen in the same cycle
      //OR read outs from other entry get written into the head entry.
      if(wr_clk_en[0])
        mem[0] <= in_sel ? data_in : rd_mx_dat;
   end
   
   //Data out always from the head entry
   assign data_out   = mem[0];

   property onehot_wrclks;
     @(posedge clk) disable iff (~rst_n) $onehot0(wr_clk_en[DEPTH-1:1]);
   endproperty
   
   property psh_on_full;
     @(posedge clk) disable iff(~rst_n) not (psh & !pop & (cnt == DEPTH));
   endproperty
   
   property pop_on_empty;
     @(posedge clk) disable iff(~rst_n) not (pop & (cnt == 0));
   endproperty

  lbl_psh_on_full: assert property (psh_on_full);
  lbl_pop_on_empty: assert property (pop_on_empty);
  lbl_onehot_wrclk: assert property (onehot_wrclks);

   
endmodule
