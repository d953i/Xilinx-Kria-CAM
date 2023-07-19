// Dual video frame buffer memory with accumulation
module RPI_CAM_CTRL # 
(
    parameter CLOCK_VALUE = 300000000
)    
(
    input wire ACLOCK,
    input wire RESETN,
     
    output wire IAS0_EN,
    output wire IAS1_EN,
    output wire RPI_PWR_EN,
    output reg RPI_LED_EN
);

reg [31:0] counter;

assign RPI_PWR_EN = 1;
assign IAS0_EN = 1;
assign IAS1_EN = 1;

always @(posedge ACLOCK) begin
    if (!RESETN) begin
        RPI_LED_EN <= 0;
        counter <= 0;
    end else begin
        counter <= counter + 1;
        if (counter == CLOCK_VALUE >> 1) begin
            counter <= 0;
            RPI_LED_EN <= ~RPI_LED_EN;
        end
    end
end

endmodule                        
