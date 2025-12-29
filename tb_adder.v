`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_adder();

    // Define internal regs and wires
    reg           clk;
    reg           resetn;
    reg  [1026:0] in_a;
    reg  [1026:0] in_b;
    reg           start;
    reg           subtract;
    wire [1027:0] result;
    wire          done;

    reg  [1027:0] expected;
    reg           result_ok;

    // Instantiating adder
    mpadder dut (
        .clk      (clk     ),
        .resetn   (resetn  ),
        .start    (start   ),
        .subtract (subtract),
        .in_a     (in_a    ),
        .in_b     (in_b    ),
        .result   (result  ),
        .done     (done    ));

    // Generate Clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end

    // Initialize signals to zero
    initial begin
        in_a     <= 0;
        in_b     <= 0;
        subtract <= 0;
        start    <= 0;
    end

    // Reset the circuit
    initial begin
        resetn = 0;
        #`RESET_TIME
        resetn = 1;
    end

    task perform_add;
        input [1026:0] a;
        input [1026:0] b;
        begin
            in_a <= a;
            in_b <= b;
            start <= 1'd1;
            subtract <= 1'd0;
            #`CLK_PERIOD;
            start <= 1'd0;
            wait (done==1);
            #`CLK_PERIOD;
        end
    endtask

    task perform_sub;
        input [1026:0] a;
        input [1026:0] b;
        begin
            in_a <= a;
            in_b <= b;
            start <= 1'd1;
            subtract <= 1'd1;
            #`CLK_PERIOD;
            start <= 1'd0;
            wait (done==1);
            #`CLK_PERIOD;
        end
    endtask

    initial begin

    #`RESET_TIME

    /*************TEST ADDITION*************/
    
    $display("\nAddition with testvector 1");
    
    // Check if 1+1=2
    #`CLK_PERIOD;
    perform_add(1027'h1, 
                1027'h1);
    expected  = 1028'h2;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;   
    
    
    $display("\nAddition with testvector 2");

    // Test addition with large test vectors. 
    // You can generate your own vectors with testvector generator python script.
    perform_add(1027'h493b6761a0b1e90b4644c7b6e9504b3724a3ab05035414db29557f9bb789fcdfc7d9a1291f73b63756e42187bf1693b0c91b83b39c5d90a62d4a20174eda45eb6d72cb5aec8e7b15565c3efaabc289db0dbc12d780a144e446e8a350eb2f0149ea50d1f65ee45e41797ccf8343bc4da82e592a6322dcf940c3dcbbdf58f29103b,
                1027'h5a5468f37ce9d90445b8193ea750d077e150df3c824b3a9ee4326c518b0b2df79c109feef81bccd00f92397f461a5ed229d42a4e730ea84492389257ca1fce5d70bc999031182e53d2879aca7aa4279f4bb313454410c495f308b6f62f599d56e6a2029f3b02d8d5d45e04c6f1fe26ca84a44101917485096e7ba0debc24a027e);
    expected  = 1028'ha38fd0551d9bc20f8bfce0f590a11baf05f48a41859f4f7a0d87ebed42952ad763ea4118178f830766765b070530f282f2efae020f6c38eabf82b26f18fa1448de2f64eb1da6a96928e3d9c52666b17a596f261cc4b2097a39f15a471a889ea0d0f2d49599e737174ddad44a35ba7472b2fd6b64b4517e4a32585cbe1517312b9;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;     
    
    $display("\nAddition with testvector seed=0");
    perform_add(1027'h41a49c8d830bd0290302d8dca53cf1e6f95eb8420de3d0bfb465aba55cf18d33cedfcea70d822fe7f3de058d75954f1edcb101ad46eef3f7b0c851c0243540cbb37db0b2b6070eb3bd60eab2a3d35a8d1f781405507c31a27df4bfbb91954206110f6b835f26111fc3673d2a75ce60a1f41a801a8e81df62b14a661b85c97bf45,
                1027'h5be9800bb35dfd40ab7b919bbdd999a9e19e604006c1f4c45b35664d5cd2867a03c99ed1883a4489b03ec3b94f65d78fe153e4594dc8cee0034734f1c0d744cd2abe14371214167a628b0646d28e7b1ead7b00811caaeee4106de5129d2e1ceedb3e472ab500bf35ee10bfd90439e64435504913feb9013ad7aaca354d246f2e7);
    expected  = 1028'h9d8e1c993669cd69ae7e6a7863168b90dafd188214a5c5840f9b11f2b9c413add2a96d7895bc7471a41cc946c4fb26aebe04e60694b7c2d7b40f86b1e50c8598de3bc4e9c81b252e1febf0f97661d5abccf314866d2720868e62a4ce2ec35ef4ec4db2ae1426d055b177fd037a0846e6296ac92e8d3ae09d88f53050d2edeb22c;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;     
    
    $display("\nAddition with testvector seed=1");
    perform_add(1027'h7d426582c4b791291d956c29d7d55c70b2f6d9bb2938b5cba145e268c162be86a24884a4eb2b32f5080a47c1aaec4e4793ad045598404ee9d81ac18e0fc8ae892ce30bc0738bfb937846b50470057075f08fdf52501b93e63e66c6e844aed030c61606436db4ffcbb6eec116e1df61006ae2ab0260b537e7c7a65f0407a6e75f5,
                1027'h649c4021706082b0ebec377a8955c0aecddc25e1ec59cd6df72b890a32442b812154bdc9edb482e160fb28dbf1530eb09b943a41b2419e74f6a2fd6e7d7bb9c7595b65c8ad9917d50c0cbee16dc4df7c0d74c5d5dd908ad146d138a626443890a7eabd01aab72ad5774e5dab41d1b5b57ae99b304d96e1505c771a7c2c677823d);
    expected  = 1028'he1dea5a4351813da0981a3a4612b1d1f80d2ff9d1592833998716b72f3a6ea07c39d426ed8dfb5d66905709d9c3f5cf82f413e974a81ed5ecebdbefc8d446850863e718921251368845373e5ddca4ff1fe04a5282dac1eb78537ff8e6af308c16e00c345186c2aa12e3d1ec223b116b5e5cc4632ae4c1938241d7980340e5f832;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;
    
    $display("\nAddition with testvector seed=2024");
    perform_add(1027'h5c5e73dcf394531550048dc95d5d36860fe8d4b76495a357a73f5f8251e3ad3e6f9d8f9becb3ad91fcb139302e752da54bb8176a178ef7854d77a3adb8564122972eb6e5fa57a9efe69b353e92177bbeb73c67385bcaf495813bbdf1b3663500202bd57940cef64c3dcedf6bcacdc0f8dde3229b46f1285388eef248e344ac794,
                1027'h5464c48c2f6d1723b283f54c2ad25ea58b479a624ef83d64688d397511cb679ceddd184be85f21747bcd2a3d360c2fffcdd70dc1467c3cc0951f6e16a43120f2bcc38a827b25f10bf4778b31b34b04f13a4cd3045c3a22bb291c466eb791c2c12db1c50cb611bafa77627f80eec035ef284fb9458b9cd2a288d87dc9619f6d770);
    expected  = 1028'hb0c3386923016a3902888315882f952b9b306f19b38de0bc0fcc98f763af14db5d7aa7e7d512cf06787e636d64815da5198f252b5e0b3445e29711c45c87621553f24168757d9afbdb12c070456280aff1893a3cb8051750aa5804606af7f7c14ddd9a85f6e0b146b5315eecb98df6e80632dbe0d28dfaf611c7701244e419f04;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;          
    
    /*************TEST SUBTRACTION*************/

    $display("\nSubtraction with testvector 1");
    
    // Check if 1-1=0
    #`CLK_PERIOD;
    perform_sub(1027'h1, 
                1027'h1);
    expected  = 1028'h0;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;    


    $display("\nSubtraction with testvector 2");

    // Test subtraction with large test vectors. 
    // You can generate your own vectors with testvector generator python script.
    perform_sub(1027'h6fb734834375c10c35cd8b58baecd83e32a5249d46f5ff6def02094d2a8733ddd742f92c882b522402700bd74004776e7498e7545abccda330761b80d520326d8762484d6b60908f74f31fd320bb8b6cc5cef91632e1a4bac9b7b946602af8bb662889e6e8ed52c178506c1f3a064581c926c23b8ff85c247827b578aff2ef518,
                1027'h716dd59f485e8c4487b824d5e6500bd021216a91d1d85cb048560a974db668281526d378533bae9acd8c1bf1099f39cfec93111fa7dcf31d2e75410d88769068da07ecdf7bf562167e52817720d03a6d6bbcd76e997dfdb5e95e393446cdfe1601b2a424b06501d121037587cc0895c7bcc96a13e3312785ad637fa6fcb330218);
    expected  = 1028'hfe495ee3fb1734c7ae156682d49ccc6e1183ba0b751da2bda6abfeb5dcd0cbb5c21c25b434efa38934e3efe636653d9e8805d634b2dfda860200da734ca9a204ad5a5b6def6b2e78f6a09e5bffeb50ff5a1221a79963a704e0598012195cfaa56475e5c2388850f0574cf6976dfdafba0c5d5827acc7349ecac435d1b33fbf300;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD; 
    
    $display("\nSubtraction with seed=0");
    perform_sub(1027'h41a49c8d830bd0290302d8dca53cf1e6f95eb8420de3d0bfb465aba55cf18d33cedfcea70d822fe7f3de058d75954f1edcb101ad46eef3f7b0c851c0243540cbb37db0b2b6070eb3bd60eab2a3d35a8d1f781405507c31a27df4bfbb91954206110f6b835f26111fc3673d2a75ce60a1f41a801a8e81df62b14a661b85c97bf45,
                1027'h5be9800bb35dfd40ab7b919bbdd999a9e19e604006c1f4c45b35664d5cd2867a03c99ed1883a4489b03ec3b94f65d78fe153e4594dc8cee0034734f1c0d744cd2abe14371214167a628b0646d28e7b1ead7b00811caaeee4106de5129d2e1ceedb3e472ab500bf35ee10bfd90439e64435504913feb9013ad7aaca354d246f2e7);
    expected  = 1028'he5bb1c81cfadd2e857874740e763583d17c058020721dbfb59304558001f06b9cb162fd58547eb5e439f41d4262f778efb5d1d53f9262517ad811cce635dfbfe88bf9c7ba3f2f8395ad5e46bd144df6e71fd138433d142be6d86daa8f467251735d12458aa2551e9d5567d5171947a5dbeca37068fc8de27d99f9be638a50cc5e;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;  
    
    $display("\nSubtraction with seed=1");
    perform_sub(1027'h7d426582c4b791291d956c29d7d55c70b2f6d9bb2938b5cba145e268c162be86a24884a4eb2b32f5080a47c1aaec4e4793ad045598404ee9d81ac18e0fc8ae892ce30bc0738bfb937846b50470057075f08fdf52501b93e63e66c6e844aed030c61606436db4ffcbb6eec116e1df61006ae2ab0260b537e7c7a65f0407a6e75f5,
                1027'h649c4021706082b0ebec377a8955c0aecddc25e1ec59cd6df72b890a32442b812154bdc9edb482e160fb28dbf1530eb09b943a41b2419e74f6a2fd6e7d7bb9c7595b65c8ad9917d50c0cbee16dc4df7c0d74c5d5dd908ad146d138a626443890a7eabd01aab72ad5774e5dab41d1b5b57ae99b304d96e1505c771a7c2c677823d);
    expected  = 1028'h18a6256154570e7831a934af4e7f9bc1e51ab3d93cdee85daa1a595e8f1e930580f3c6dafd76b013a70f1ee5b9993f96f818ca13e5feb074e177c41f924cf4c1d387a5f7c5f2e3be6c39f623024090f9e31b197c728b0914f7958e421e6a97a01e2b4941c2fdd4f63fa0636ba00dab4aeff90fd2131e56976b2f4487db3f6f3b8;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;  
    
    $display("\nSubtraction with seed=2024");
    perform_sub(1027'h5c5e73dcf394531550048dc95d5d36860fe8d4b76495a357a73f5f8251e3ad3e6f9d8f9becb3ad91fcb139302e752da54bb8176a178ef7854d77a3adb8564122972eb6e5fa57a9efe69b353e92177bbeb73c67385bcaf495813bbdf1b3663500202bd57940cef64c3dcedf6bcacdc0f8dde3229b46f1285388eef248e344ac794,
                1027'h5464c48c2f6d1723b283f54c2ad25ea58b479a624ef83d64688d397511cb679ceddd184be85f21747bcd2a3d360c2fffcdd70dc1467c3cc0951f6e16a43120f2bcc38a827b25f10bf4778b31b34b04f13a4cd3045c3a22bb291c466eb791c2c12db1c50cb611bafa77627f80eec035ef284fb9458b9cd2a288d87dc9619f6d770);
    expected  = 1028'h7f9af50c4273bf19d80987d328ad7e084a13a55159d65f33eb2260d401845a181c0775004548c1d80e40ef2f868fda57de109a8d112bac4b85835971425202fda6b2c637f31b8e3f223aa0cdecc76cd7cef9433ff90d1da581f7782fbd4723ef27a106c8abd3b51c66c5feadc0d8b09b5936955bb5455b10016747f81a53f024;
    wait (done==1);
    result_ok = (expected==result);
    $display("result calculated=%x", result);
    $display("result expected  =%x", expected);
    $display("error            =%x", expected-result);
    #`CLK_PERIOD;  
       
    
    $finish;

    end

endmodule