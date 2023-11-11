`timescale 1ns / 1ns

`define TOTAL_CYCLES 100
`define CYCLE 50
`define TEST_CASE 10

module fpu_tb;

  reg clk;
  reg rst;
  wire [15:0] in1, in2, out;
  reg     [15:0] golden;
  reg     [ 3:0] op;
  wire           overflow;

  reg     [15:0] add_ans  [`TEST_CASE - 1 : 0];
  reg     [15:0] mul_ans  [`TEST_CASE - 1 : 0];
  reg     [15:0] in1_mem  [`TEST_CASE - 1 : 0];
  reg     [15:0] in2_mem  [`TEST_CASE - 1 : 0];

  reg     [15:0] count;
  reg            fin;

  integer        error;

  fpu ul (
      .op_i      (op),
      .in1_i     (in1),
      .in2_i     (in2),
      .out_o     (out),
      .overflow_o(overflow)
  );

  always #(`CYCLE / 2) clk = ~clk;

`ifdef SDF
  initial $sdf_annotate(`SDFFILE, ul);
`endif

  // Initialization
  initial begin
    clk   = 1'b0;
    error = 32'b0;
    count = 16'b0;
  end

  initial begin
    $readmemh("INPUT_A.txt", in1_mem, 0, `TEST_CASE - 1);
    $readmemh("INPUT_B.txt", in2_mem, 0, `TEST_CASE - 1);
    $readmemh("ADD.txt", add_ans, 0, `TEST_CASE - 1);
    $readmemh("MUL.txt", mul_ans, 0, `TEST_CASE - 1);
  end

  initial begin
    `ifdef MUL
      assign op = 4'b0100;
    `elsif ADD
      assign op = 4'b0001;
    `else 
      $error("Option %s not recognized, assume MUL");
      assign op = 4'b0100;
    `endif
  end

  initial begin
    rst = 1;
    #`CYCLE;
    rst = 0;
    fin = 0;
    #(`TOTAL_CYCLES * `CYCLE);
    fin = 1;
    #1;
    $finish;
  end

  assign in1 = in1_mem[count];
  assign in2 = in2_mem[count];

  always @(posedge clk) begin
    if (rst) count <= 16'b0;
    else count <= count + 16'b1;
  end

  //  always @(posedge clk) begin
  always @(*) begin
    case (op)
      4'b0001: golden = add_ans[count];
      4'b0100: golden = mul_ans[count];
      default: golden = 16'hx;
    endcase
  end

  always @(negedge clk) begin
    if (rst) error <= 0;
    else begin
      if (out !== golden) begin  // Exact match
        $write("Error at %0dth cycle:\n", count);
        $write("Input1: %h, Input2: %h, Real answer: %h, Your answer: %b %h\n", in1, in2, golden,
               out, out);
        error <= error + 1;
      end
    end
  end

  always @(posedge fin) begin
    if (error) begin
      $display("\n");
      $display(
          "====================================================================================");
      $display(
          "-------------- (/`n`)/ ~#  There was %2d errors in your code !! ---------------------",
          error);
      $display(
          "-------------- (/`n`)/ ~#  There was %2d test cases in your code !! -----------------",
          `TEST_CASE);
      $display(
          "--------- The simulation has finished with some error, Please check it !!! ---------");
      $display(
          "====================================================================================");
      $display("\n");
    end else begin
      $display("\n");
      $display("        ****************************               ");
      $display("        **                        **       /|__/|  ");
      $display("        **  Congratulations !!    **      / O,O  | ");
      $display("        **                        **    /_____   | ");
      $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
      $display("        **                        **  |^ ^ ^ ^ |w| ");
      $display("        *************** ************   \\m___m__|_|");
      $display("\n");
    end
  end

endmodule