module fsm(
    input wire clk,
    input wire clk_dsp,
    input wire rst,
    input wire gtx_done,
    input wire prbs_start,
    input wire [3:0][1:0] prbs_error,
    output reg gtx_reset,
    output reg prbs_counter_reset,
    output reg [3:0] error_display,
    output reg [7:0] led_output
);

    reg [1:0] state, next_state;
    reg [3:0] cycle_counter;

    parameter RESET_GTX = 2'b00;
    parameter WAIT_PRBS_START = 2'b01;
    parameter RESET_PRBS_COUNTER = 2'b10;
    parameter FREE_RUN_ERROR = 2'b11;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= RESET_GTX;
        else
            state <= next_state;
    end

    always @(*) begin
        gtx_reset = 0;
        prbs_counter_reset = 0;
        error_display = 4'b0000;
        led_output = 8'b00000000;
        next_state = state;
        
        case (state)
            RESET_GTX: begin
                gtx_reset = 1;
                if (gtx_done)
                    next_state = WAIT_PRBS_START;
            end
            
            WAIT_PRBS_START: begin
                if (prbs_start)
                    next_state = RESET_PRBS_COUNTER;
            end
            
            RESET_PRBS_COUNTER: begin
                prbs_counter_reset = 1;
                next_state = FREE_RUN_ERROR;
            end
            
            FREE_RUN_ERROR: begin
                error_display = prbs_error[cycle_counter];
                
                led_output[0] = clk_dsp; // Blinking heartbeat
                led_output[4:1] = cycle_counter; // Link Addresses 0-3
                led_output[6:5] = prbs_error[cycle_counter]; // Display PRBS error data
                led_output[7] = |prbs_error; // Error in any channel
            end
        endcase
    end

    always @(posedge clk_dsp or posedge rst) begin
        if (rst)
            cycle_counter <= 0;
        else if (state == FREE_RUN_ERROR)
            cycle_counter <= (cycle_counter == 4'd10) ? 0 : cycle_counter + 1;
    end

endmodule
