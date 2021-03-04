//Module finds if the requestors are one hot by asserting OnlyOneSet
//If more than one requestor is set, the requestor from LSB is given higher priority, an enocded value of the requestor is also provided
module findOnlyOneSet #(
                       parameter WIDTH = 8,
                       parameter SIZE = $clog2(WIDTH))
   ( input [WIDTH-1:0] Req,
    output logic OnlyOneSet,
    output logic [WIDTH-1:0] OneHotReq,
    output logic [SIZE-1:0]   EncOneHotReq);

   logic [SIZE:0][WIDTH-1:0] AndTerm,OrTerm;
   logic [SIZE:0][WIDTH-1:0][WIDTH-1:0]  ReqMux;
   logic [SIZE:0][WIDTH-1:0][SIZE-1:0]    EncReqMux;

   //SIZE = leaf nodes
   assign AndTerm[SIZE]             = '0;
   assign OrTerm[SIZE]              = Req;

   //O = Top of Tree
   assign OnlyOneSet                = ~AndTerm[0];
   assign OneHotReq[WIDTH-1:0]      = ReqMux[0][WIDTH-1:0];
   assign EncOneHotReq[SIZE-1:0]     = EncReqMux[0][SIZE-1:0];
   
   always_comb begin
      ReqMux     = 'x;
      EncReqMux = '0;
      //Assign leaf level to incoming Req's
      for(int i=0; i<WIDTH;i++)
        ReqMux[SIZE][i][WIDTH-1:0] = {{WIDTH-1{1'b0}},Req[i]};
      
      for(int LVL=SIZE-1; LVL>=0; LVL--) begin
         for(int NODE=0; NODE<(1<< LVL); NODE++) begin
            AndTerm[LVL][NODE] =  |AndTerm[LVL+1][2*NODE+:2] | &OrTerm[LVL+1][2*NODE+:2];
            OrTerm[LVL][NODE]  =  |OrTerm [LVL+1][2*NODE+:2];

            //bring the default requestor up, and also encode it.
            ReqMux    [LVL][NODE][WIDTH-1:0] = ReqMux    [LVL+1][2*NODE+1][WIDTH-1:0];
            EncReqMux[LVL][NODE][SIZE-1:0]    = EncReqMux[LVL+1][2*NODE+1][SIZE-1:0] | 1 << (SIZE-1-LVL);
            if(ReqMux[LVL+1][2*NODE+0]) begin //If high priority requestor is set, then overwrite the default
               ReqMux   [LVL][NODE][WIDTH-1:0] = ReqMux    [LVL+1][2*NODE+0][WIDTH-1:0];
               EncReqMux[LVL][NODE][SIZE-1:0]   = EncReqMux[LVL+1][2*NODE+0][SIZE-1:0];
            end
         end
      end
   end



endmodule
