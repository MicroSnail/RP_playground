
/*
XPM_FIFO instantiation template for Asynchronous FIFO configurations
Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
=======================================================================================================================

Parameter usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Parameter name          | Data type          | Restrictions, if applicable                                          |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| FIFO_MEMORY_TYPE        | String             | Must be "auto", "block", or "distributed"                            |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the fifo memory primitive (resource type) to use:                                                         |
|   "auto": Allow Vivado Synthesis to choose                                                                          |
|   "block": Block RAM FIFO                                                                                           |
|   "distributed": Distributed RAM FIFO                                                                               |
+---------------------------------------------------------------------------------------------------------------------+
| FIFO_WRITE_DEPTH        | Integer            | Must be between 16 and 4194304                                       |
|---------------------------------------------------------------------------------------------------------------------|
| Defines the FIFO Write Depth, must be power of two                                                                  |
| In standard READ_MODE, the effective depth = FIFO_WRITE_DEPTH-1                                                     |
| In First-Word-Fall-Through READ_MODE, the effective depth = FIFO_WRITE_DEPTH+1                                      |
+---------------------------------------------------------------------------------------------------------------------+
| RELATED_CLOCKS          | Integer            | Must be 0 or 1                                                       |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies if the wr_clk and rd_clk are related having the same source but different clock ratios                    |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_DATA_WIDTH        | Integer            | Must be between 1 and 4096                                           |
|---------------------------------------------------------------------------------------------------------------------|
| Defines the width of the write data port, din                                                                       |
+---------------------------------------------------------------------------------------------------------------------+
| WR_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_WRITE_DEPTH)+1                       |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the width of wr_data_count                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| READ_MODE               | String             | Must be "std" or "fwft"                                              |
|---------------------------------------------------------------------------------------------------------------------|
|  "std": standard read mode                                                                                          |
|  "fwft": First-Word-Fall-Through read mode                                                                          |
+---------------------------------------------------------------------------------------------------------------------+
| FIFO_READ_LATENCY       | Integer            | Must be >= 0                                                         |
|---------------------------------------------------------------------------------------------------------------------|
|  Number of output register stages in the read data path                                                             |
|  If READ_MODE = "fwft", then the only applicable value is 0.                                                        |
+---------------------------------------------------------------------------------------------------------------------+
| FULL_RESET_VALUE        | Integer            | Must be 0 or 1                                                       |
|---------------------------------------------------------------------------------------------------------------------|
|  Sets FULL and PROG_FULL to FULL_RESET_VALUE during reset                                                           |
+---------------------------------------------------------------------------------------------------------------------+
| READ_DATA_WIDTH         | Integer            | Must be between >= 1                                                 |
|---------------------------------------------------------------------------------------------------------------------|
| Defines the width of the read data port, dout                                                                       |
+---------------------------------------------------------------------------------------------------------------------+
| RD_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_READ_DEPTH)+1                        |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the width of rd_data_count                                                                                |
| FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH                                                 |
+---------------------------------------------------------------------------------------------------------------------+
| CDC_SYNC_STAGES         | Integer            | Must be between 2 to 8                                               |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the number of synchronization stages on the CDC path                                                      |
+---------------------------------------------------------------------------------------------------------------------+
| ECC_MODE                | String             | Must be "no_ecc" or "en_ecc"                                         |
|---------------------------------------------------------------------------------------------------------------------|
| "no_ecc" : Disables ECC                                                                                             |
| "en_ecc" : Enables both ECC Encoder and Decoder                                                                     |
+---------------------------------------------------------------------------------------------------------------------+
| PROG_FULL_THRESH        | Integer            | Must be between "Min_Value" and "Max_Value"                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
| Min_Value = 3 + (READ_MODE*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))+CDC_SYNC_STAGES                                    |
| Min_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))                                 |
+---------------------------------------------------------------------------------------------------------------------+
| PROG_EMPTY_THRESH       | Integer            | Must be between "Min_Value" and "Max_Value"                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted                     |
| Min_Value = 3 + (READ_MODE*2)                                                                                       |
| Min_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE*2)                                                                    |
+---------------------------------------------------------------------------------------------------------------------+
| DOUT_RESET_VALUE        | String             | Must be >="0". Valid hexa decimal value                              |
|---------------------------------------------------------------------------------------------------------------------|
| Reset value of read data path.                                                                                      |
+---------------------------------------------------------------------------------------------------------------------+
| WAKEUP_TIME             | Integer            | Must be 0 or 2                                                       |
|---------------------------------------------------------------------------------------------------------------------|
| 0 : Disable sleep.                                                                                                  |
| 2 : Use Sleep Pin.                                                                                                  |
+---------------------------------------------------------------------------------------------------------------------+

Port usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Port name      | Direction | Size, in bits                         | Domain | Sense       | Handling if unused      |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| sleep          | Input     | 1                                     |        | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.                              |
| Synchronous to the slower of wr_clk and rd_clk.                                                                     |
+---------------------------------------------------------------------------------------------------------------------+
| rst            | Input     | 1                                     | wr_clk | Active-high | Required                |
+---------------------------------------------------------------------------------------------------------------------+
| wr_clk         | Input     | 1                                     |        | Rising edge | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write clock: Used for write operation.                                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| wr_en          | Input     | 1                                     | wr_clk | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO         |
+---------------------------------------------------------------------------------------------------------------------+
| din            | Input     | WRITE_DATA_WIDTH                      | wr_clk |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write Data: The input data bus used when writing the FIFO.                                                          |
+---------------------------------------------------------------------------------------------------------------------+
| full           | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Full Flag: When asserted, this signal indicates that the FIFO is full.                                              |
| Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive       |
| to the contents of the FIFO.                                                                                        |
+---------------------------------------------------------------------------------------------------------------------+
| overflow       | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected,              |
| because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.                      |
+---------------------------------------------------------------------------------------------------------------------+
| wr_rst_busy    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.                   |
+---------------------------------------------------------------------------------------------------------------------+
| rd_clk         | Input     | 1                                     |        | Rising edge | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Read clock: Used for read operation.                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| rd_en          | Input     | 1                                     | rd_clk | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO         |
+---------------------------------------------------------------------------------------------------------------------+
| dout           | Output    | READ_DATA_WIDTH                       | rd_clk |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Read Data: The output data bus is driven when reading the FIFO.                                                     |
+---------------------------------------------------------------------------------------------------------------------+
| empty          | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Empty Flag: When asserted, this signal indicates that the FIFO is empty.                                            |
| Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.     |
+---------------------------------------------------------------------------------------------------------------------+
| underflow      | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected                     |
| because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.                                   |
+---------------------------------------------------------------------------------------------------------------------+
| rd_rst_busy    | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.                     |
+---------------------------------------------------------------------------------------------------------------------+
| prog_full      | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
| to the programmable full threshold value.                                                                           |
| It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
+---------------------------------------------------------------------------------------------------------------------+
| wr_data_count  | Output    | WR_DATA_COUNT_WIDTH                   | wr_clk |             | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
+---------------------------------------------------------------------------------------------------------------------+
| prog_empty     | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal              |
| to the programmable empty threshold value.                                                                          |
| It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
+---------------------------------------------------------------------------------------------------------------------+
| rd_data_count  | Output    | RD_DATA_COUNT_WIDTH                   | rd_clk |             | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Read Data Count: This bus indicates the number of words read from the FIFO.                                         |
+---------------------------------------------------------------------------------------------------------------------+
| injectsbiterr  | Intput    | 1                                     |        | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or                  |
| built-in FIFO macros.                                                                                               |
+---------------------------------------------------------------------------------------------------------------------+
| injectdbiterr  | Intput    | 1                                     |        | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or                  |
| built-in FIFO macros.                                                                                               |
+---------------------------------------------------------------------------------------------------------------------+
| sbiterr        | Output    | 1                                     |        | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.                             |
+---------------------------------------------------------------------------------------------------------------------+
| dbiterr        | Output    | 1                                     |        | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
+---------------------------------------------------------------------------------------------------------------------+
*/

//  xpm_fifo_async      : In order to incorporate this function into the design, the following module instantiation
//       Verilog        : needs to be placed in the body of the design code.  The default values for the parameters
//        module        : may be changed to meet design requirements.  The instance name (xpm_fifo_async)
//     instantiation    : and/or the port declarations within the parenthesis may be changed to properly reference and
//         code         : connect this function to the design.  All inputs and outputs must be connected, unless
//                      : otherwise specified.

//  <--Cut the following instance declaration and paste it into the design-->

// xpm_fifo_async: Asynchronous FIFO
// Xilinx Parameterized Macro, Version 2016.4
xpm_fifo_async # (

  .FIFO_MEMORY_TYPE          ("block"),           //string; "auto", "block", or "distributed";
  .ECC_MODE                  ("no_ecc"),         //string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
  .FIFO_WRITE_DEPTH          (2048),             //positive integer
  .WRITE_DATA_WIDTH          (32),               //positive integer
  .WR_DATA_COUNT_WIDTH       (12),               //positive integer
  .PROG_FULL_THRESH          (10),               //positive integer
  .FULL_RESET_VALUE          (0),                //positive integer; 0 or 1
  .READ_MODE                 ("std"),            //string; "std" or "fwft";
  .FIFO_READ_LATENCY         (1),                //positive integer;
  .READ_DATA_WIDTH           (32),               //positive integer
  .RD_DATA_COUNT_WIDTH       (12),               //positive integer
  .PROG_EMPTY_THRESH         (10),               //positive integer
  .DOUT_RESET_VALUE          ("0"),              //string
  .CDC_SYNC_STAGES           (2),                //positive integer
  .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;

) xpm_fifo_async_inst (

  .rst              (rst),
  .wr_clk           (wr_clk),
  .wr_en            (wr_en),
  .din              (din),
  .full             (full),
  .overflow         (overflow),
  .wr_rst_busy      (wr_rst_busy),
  .rd_clk           (rd_clk),
  .rd_en            (rd_en),
  .dout             (dout),
  .empty            (empty),
  .underflow        (underflow),
  .rd_rst_busy      (rd_rst_busy),
  .prog_full        (prog_full),
  .wr_data_count    (wr_data_count),
  .prog_empty       (prog_empty),
  .rd_data_count    (rd_data_count),
  .sleep            (1'b0),
  .injectsbiterr    (1'b0),
  .injectdbiterr    (1'b0),
  .sbiterr          (),
  .dbiterr          ()

);

// End of xpm_fifo_async instance declaration


      
      