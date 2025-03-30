module LCD_CTRL(clk,
                reset,
                cmd,
                cmd_valid,
                IROM_Q,
                IROM_rd,
                IROM_A,
                IRAM_valid,
                IRAM_D,
                IRAM_A,
                busy,
                done);
    input clk;
    input reset;
    input [3:0] cmd;
    input cmd_valid;
    input [7:0] IROM_Q;
    output IROM_rd;
    output [5:0] IROM_A;
    output IRAM_valid;
    output [7:0] IRAM_D;
    output [5:0] IRAM_A;
    output busy;
    output done;

    reg IROM_rd;
    //reg [5:0] IROM_A;
    reg IRAM_valid;
    reg [7:0] IRAM_D;
    //reg [5:0] IRAM_A;
    reg busy;
    reg done;
    reg [2:0] cs,ns;
    reg [7:0] img_r [63:0] ;
    reg [2:0] x,Y;
    reg en;
    reg [5:0] AA;
    wire [5:0] IRAM_A;
    wire [5:0] IROM_A;

    wire [5:0]  a1, a2, a3, a4; ///4格
    wire [5:0] X_8Y;
    
    parameter   READ=0,CMD=1,WRITE=2;
    parameter   shift_up=4'h1,shift_down=4'h2,shift_left=4'h3,shift_right=4'h4,max=4'h5,
                min=4'h6,average=4'h7,counterclockwise=4'h8,clockwise=4'h9,mirror_x=4'ha,mirror_y=4'hb;

    assign  X_8Y = 8*Y+x;
    assign  a1 = X_8Y-9;
    assign  a2 = X_8Y-8;
    assign  a3 = X_8Y-1;
    assign  a4 = X_8Y;

    assign IRAM_A = AA;
    assign IROM_A = AA;

    //max
    wire[7:0] img_max;
    assign img_max = (img_r[a1] > img_r[a2]) ? //a1>a2?
                    (img_r[a1] > img_r[a3]) ? //a1>a3?
                    (img_r[a1] > img_r[a4]) ? img_r[a1] : img_r[a4] //a1>a4?
                    : 
                    (img_r[a3] > img_r[a4]) ? img_r[a3] : img_r[a4] //a3>a1 & a3>a2 but a3>a4?
                    : 
                    (img_r[a2] > img_r[a3]) ? //a2>a1 but a2>a3?
                    (img_r[a2] > img_r[a4]) ? img_r[a2] : img_r[a4] //a2>a1 & a2>a3 but a2>a4?
                    : 
                    (img_r[a3] > img_r[a4]) ? img_r[a3] : img_r[a4]; //a3>a2 & a3>a1 but a3>a4?
    //min
    wire[7:0] img_min;
    assign img_min = (img_r[a1] < img_r[a2]) ? //a1>a2?
                    (img_r[a1] < img_r[a3]) ? //a1>a3?
                    (img_r[a1] < img_r[a4]) ? img_r[a1] : img_r[a4] //a1>a4?
                    : 
                    (img_r[a3] < img_r[a4]) ? img_r[a3] : img_r[a4] //a3>a1 & a3>a2 but a3>a4?
                    : 
                    (img_r[a2] < img_r[a3]) ? //a2>a1 but a2>a3?
                    (img_r[a2] < img_r[a4]) ? img_r[a2] : img_r[a4] //a2>a1 & a2>a3 but a2>a4?
                    : 
                    (img_r[a3] < img_r[a4]) ? img_r[a3] : img_r[a4]; //a3>a2 & a3>a1 but a3>a4?
    //avg
    wire[7:0] img_avg;
    assign img_avg = (img_r[a1]+img_r[a2]+img_r[a3]+img_r[a4])/4 ;

    ///
    always @(posedge clk or posedge reset) begin
        if(reset)begin
            cs <= 3'd0;
            cs[READ] <= 1'd1; 
        end
        else cs <= ns;
    end

    ///
    always @(*) begin   
        ns = 3'd0;
        case (1'd1)
            cs[READ]:begin
                if(IROM_A==6'd63) ns[CMD] = 1'd1;
                else ns[READ] = 1'd1;
            end
            cs[CMD]:begin
                if(cmd==4'd0 && cmd_valid==1'd1) ns[WRITE] = 1'd1;
                else ns[CMD] = 1'd1;
            end
            cs[WRITE]: ns[WRITE] = 1'd1;
            default: ns[READ] = 1'd1;
        endcase
    end
    
    always@(posedge clk or posedge reset) begin
        if(reset)begin
            AA <= 6'd0;
            IROM_rd <= 1'd1;
            x <= 3'd4;
            Y <= 3'd4;
            busy <= 1'd1;
            IRAM_valid <= 1'd0;
            AA <= 6'd0;
            done <= 1'd0;
            en <= 1'd1;
        end
        else begin
            case (1'd1)
                cs[READ]:begin
                    IROM_rd <=1'd1;
                    img_r[AA] <= IROM_Q;
                    AA <= AA+6'd1;
                    if(AA==6'd63) busy <= 1'd0;
                    else busy <= 1'd1;
                end 
                cs[CMD]:begin
                    AA <= 6'd0;
                    if(cmd_valid)begin
                        case (cmd)
                            shift_up: begin
                                if(Y==3'd1)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x;
                                    Y <= Y-3'd1;
                                end
                            end
                            shift_down:begin
                                if(Y==3'd7)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x;
                                    Y <= Y+3'd1;
                                end
                            end
                            shift_left:begin
                                if(x==3'd1)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x-3'd1;
                                    Y <= Y;
                                end
                            end
                            shift_right:begin
                                if(x==3'd7)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x+3'd1;
                                    Y <= Y;
                                end
                            end
                            max:begin
                                img_r[a1] <= img_max;
                                img_r[a2] <= img_max;
                                img_r[a3] <= img_max;
                                img_r[a4] <= img_max;
                            end
                            min:begin
                                img_r[a1] <= img_min;
                                img_r[a2] <= img_min;
                                img_r[a3] <= img_min;
                                img_r[a4] <= img_min;
                            end
                            average:begin
                                img_r[a1] <= img_avg;
                                img_r[a2] <= img_avg;
                                img_r[a3] <= img_avg;
                                img_r[a4] <= img_avg;
                            end
                            counterclockwise:begin
                                img_r[a1] <= img_r[a2];
                                img_r[a2] <= img_r[a4];
                                img_r[a3] <= img_r[a1];
                                img_r[a4] <= img_r[a3];
                            end
                            clockwise:begin
                                img_r[a1] <= img_r[a3];
                                img_r[a2] <= img_r[a1];
                                img_r[a3] <= img_r[a4];
                                img_r[a4] <= img_r[a2];
                            end
                            mirror_x:begin
                                img_r[a1] <= img_r[a3];
                                img_r[a2] <= img_r[a4];
                                img_r[a3] <= img_r[a1];
                                img_r[a4] <= img_r[a2];
                            end
                            mirror_y:begin
                                img_r[a1] <= img_r[a2];
                                img_r[a2] <= img_r[a1];
                                img_r[a3] <= img_r[a4];
                                img_r[a4] <= img_r[a3];
                            end
                        endcase
                    end 
                    else busy <= 1'd0;
                end
                cs[WRITE]:begin
                    if(AA==6'd63)begin
                        busy <= 1'd0;
                        done <= 1'd1;
                        AA <= 6'd63;
                    end
                    else begin
                        IRAM_valid <= 1'd1;
                        if(en)begin
                           en <= 1'd0;
                           AA <= 6'd0; 
                           IRAM_D <= img_r[AA];
                        end
                        else begin
                            en <= 1'd0;
                            AA <= AA+6'd1;
                            IRAM_D <= img_r[AA+6'd1];                                                        
                        end
                    end
                end
                
            endcase
        end
    end 
   
endmodule

    ///
    /*
    always@(posedge clk or posedge reset) begin
        if(reset)begin
            IROM_A <= 6'd0;
            IROM_rd <= 1'd1;
            x <= 3'd4;
            Y <= 3'd4;
            busy <= 1'd1;
            IRAM_valid <= 1'd0;
            IRAM_A <= 6'd0;
            done <= 1'd0;
            en <= 1'd1;
        end
        else begin
            case (1'd1)
                cs[READ]:begin
                    IROM_rd <=1'd1;
                    img_r[IROM_A] <= IROM_Q;
                    IROM_A <= IROM_A+6'd1;
                    if(IROM_A==6'd63) busy <= 1'd0;
                    else busy <= 1'd1;
                end 
                cs[CMD]:begin
                    if(cmd_valid)begin
                        case (cmd)
                            shift_up: begin
                                if(Y==3'd1)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x;
                                    Y <= Y-3'd1;
                                end
                            end
                            shift_down:begin
                                if(Y==3'd7)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x;
                                    Y <= Y+3'd1;
                                end
                            end
                            shift_left:begin
                                if(x==3'd1)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x-3'd1;
                                    Y <= Y;
                                end
                            end
                            shift_right:begin
                                if(x==3'd7)begin
                                    x <= x;
                                    Y <= Y;
                                end
                                else begin
                                    x <= x+3'd1;
                                    Y <= Y;
                                end
                            end
                            max:begin
                                img_r[a1] <= img_max;
                                img_r[a2] <= img_max;
                                img_r[a3] <= img_max;
                                img_r[a4] <= img_max;
                            end
                            min:begin
                                img_r[a1] <= img_min;
                                img_r[a2] <= img_min;
                                img_r[a3] <= img_min;
                                img_r[a4] <= img_min;
                            end
                            average:begin
                                img_r[a1] <= img_avg;
                                img_r[a2] <= img_avg;
                                img_r[a3] <= img_avg;
                                img_r[a4] <= img_avg;
                            end
                            counterclockwise:begin
                                img_r[a1] <= img_r[a2];
                                img_r[a2] <= img_r[a4];
                                img_r[a3] <= img_r[a1];
                                img_r[a4] <= img_r[a3];
                            end
                            clockwise:begin
                                img_r[a1] <= img_r[a3];
                                img_r[a2] <= img_r[a1];
                                img_r[a3] <= img_r[a4];
                                img_r[a4] <= img_r[a2];
                            end
                            mirror_x:begin
                                img_r[a1] <= img_r[a3];
                                img_r[a2] <= img_r[a4];
                                img_r[a3] <= img_r[a1];
                                img_r[a4] <= img_r[a2];
                            end
                            mirror_y:begin
                                img_r[a1] <= img_r[a2];
                                img_r[a2] <= img_r[a1];
                                img_r[a3] <= img_r[a4];
                                img_r[a4] <= img_r[a3];
                            end
                        endcase
                    end 
                    else busy <= 1'd0;
                end
                cs[WRITE]:begin
                    if(IRAM_A==6'd63)begin
                        busy <= 1'd0;
                        done <= 1'd1;
                        IRAM_A <= 6'd63;
                    end
                    else begin
                        IRAM_valid <= 1'd1;
                        if(en)begin
                           en <= 1'd0;
                           IRAM_A <= 6'd0; 
                           IRAM_D <= img_r[IRAM_A];
                        end
                        else begin
                            en <= 1'd0;
                            IRAM_A <= IRAM_A+6'd1;
                            IRAM_D <= img_r[IRAM_A+6'd1];                                                        
                        end
                    end
                end
                
            endcase
        end
    end */