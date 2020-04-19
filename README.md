# SVerilog
SystemVerilog common use modules
module muxN : takes in #WIDTH inputs, and outputs #NUM_SEL requested outputs.
            : also mux's #WIDTH data_in and creates #NUM_SEL outputs.
            : usually picks requests from left of the tree, and if no requests found Or's in request from the right.
            : also outputs onehot and encoded forms of selected requests.
            : expects a complete binary tree. 
            : User can pad 0's outside the module to form a complete tree. No error checking performed in the module.
