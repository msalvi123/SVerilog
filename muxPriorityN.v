module muxN#(parameter DIR_L2H    = 1,              //Direction of Priority
             parameter WIDTH      = 8,              //Number of inputs.
             parameter SIZE       = $clog2(WIDTH),  //Log2 Number of inputs
             parameter DATA_WIDTH = 4,              //Width of data  
             parameter NUM_SEL    = 3)              //Number of muxed outputs   (
   
   (input  [WIDTH-1:0]                         req_in,
    input [WIDTH-1:0] [DATA_WIDTH-1:0]         data_in,
    
    output logic [NUM_SEL-1:0]                 req_sum,
    output logic [NUM_SEL-1:0][DATA_WIDTH-1:0] data_out,
    output logic [NUM_SEL-1:0][WIDTH-1:0]      req_out,
    output logic [NUM_SEL-1:0][SIZE-1:0]       enc_req_out);
   
   localparam INIT_IDX  =  DIR_L2H ? 0 : NUM_SEL-1;
   
   logic [SIZE:0][WIDTH-1:0][NUM_SEL-1:0][DATA_WIDTH-1:0] data_mux;
   logic [SIZE:0][WIDTH-1:0][NUM_SEL-1:0][WIDTH-1:0]  req_mux;
   logic [SIZE:0][WIDTH-1:0][NUM_SEL-1:0][SIZE-1:0]  enc_req_mux;
   logic [SIZE:0][WIDTH-1:0][NUM_SEL-1:0]  sum;
   logic  block;
   logic [NUM_SEL-1:0]  rem_sel;
   
   int    MAX_BKT_AT_LVL;
   int    MAX_BKT_LOWER_LVL,NODE,LVL;
   
   assign data_out   [NUM_SEL-1:0] = data_mux   [0][0][NUM_SEL-1:0];
   assign req_out    [NUM_SEL-1:0] = req_mux    [0][0][NUM_SEL-1:0];
   assign enc_req_out[NUM_SEL-1:0] = enc_req_mux[0][0][NUM_SEL-1:0];
   assign req_sum    [NUM_SEL-1:0] = sum        [0][0];  
   
   
   //Initialize leaf's of tree to data_in
   always_comb begin
      data_mux    = '0;
      req_mux     = '0;
      sum         = '0;
      enc_req_mux = '0;
      
      for(int i=0;i<WIDTH;i++) begin
         data_mux   [SIZE][i][0]            = data_in[i];
         req_mux    [SIZE][i][0][WIDTH-1:0] = req_in [i];
         sum        [SIZE][i][0]            = req_in [i];
      end
     
      for(LVL=SIZE-1; LVL>=0; LVL--) begin
         for(NODE=0; NODE < 1 << LVL; NODE++) begin
            MAX_BKT_LOWER_LVL            = ((1 << SIZE-LVL-1) >  NUM_SEL) ? NUM_SEL : (1 << (SIZE-LVL-1));
            MAX_BKT_AT_LVL               = ((1 << SIZE-LVL)   >  NUM_SEL) ? NUM_SEL : (1 << (SIZE-LVL));
            
            //Default:Pull lower level up
            for(int bkt=0; bkt < MAX_BKT_LOWER_LVL; bkt++) begin:BKT_DEF
               req_mux    [LVL][NODE][bkt] =  req_mux    [LVL+1][2*NODE + DIR_L2H][bkt] << (DIR_L2H << SIZE-LVL-1);
               data_mux   [LVL][NODE][bkt] =  data_mux   [LVL+1][2*NODE + DIR_L2H][bkt];
               enc_req_mux[LVL][NODE][bkt] =  enc_req_mux[LVL+1][2*NODE + DIR_L2H][bkt] | (DIR_L2H << (SIZE-1-LVL));
               sum        [LVL][NODE][bkt] =  sum        [LVL+1][2*NODE + DIR_L2H][bkt];
            end
            
            //If the priority side has elements, pull those up while shifting the default elements.
            for(int bkt = MAX_BKT_LOWER_LVL-1; bkt >= 0; bkt--) begin:BKT_RGT
               if(sum[LVL+1][2*NODE+!DIR_L2H][bkt]) begin
                  for(int l=MAX_BKT_AT_LVL-2; l>=0; l--) begin: SHFT_LFT
                     req_mux    [LVL][NODE][l+1] =  req_mux    [LVL][NODE][l];
                     data_mux   [LVL][NODE][l+1] =  data_mux   [LVL][NODE][l];
                     enc_req_mux[LVL][NODE][l+1] =  enc_req_mux[LVL][NODE][l];
                     sum        [LVL][NODE][l+1] =  sum        [LVL][NODE][l];
                     //
                  end
                  req_mux    [LVL][NODE][0] =  req_mux    [LVL+1][2*NODE + !DIR_L2H][bkt] << ((DIR_L2H ? 0 : 1) << (SIZE-LVL-1));
                  data_mux   [LVL][NODE][0] =  data_mux   [LVL+1][2*NODE + !DIR_L2H][bkt];
                  enc_req_mux[LVL][NODE][0] =  enc_req_mux[LVL+1][2*NODE + !DIR_L2H][bkt] | (!DIR_L2H << (SIZE-1-LVL));
                  sum        [LVL][NODE][0] =  sum        [LVL+1][2*NODE + !DIR_L2H][bkt];
               end
            end
            //$display("LVL %d, NODE %d, MAX_BKT_AT_LVL %d, data_mux %h",LVL,2*NODE+!DIR_L2H,MAX_BKT_AT_LVL,req_mux[LVL][NODE][bkt]);
         end
      end
   end
endmodule
