/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description: 
 * Table of positions (LUT) mapping crate ID (0-31) to global map coordinates.
 * Coordinates are kept for 2048x2048 map resolution.
 */

 module crate_lut (
    input  logic [4:0]  crate_id,
    output logic [11:0] crate_x,
    output logic [11:0] crate_y
);

always_comb begin
    case (crate_id)
        5'd0: begin
            crate_x = 12'd208;
            crate_y = 12'd80;
        end
        5'd1: begin
            crate_x = 12'd1808;
            crate_y = 12'd80;
        end
        5'd2: begin
            crate_x = 12'd912;
            crate_y = 12'd208;
        end
        5'd3: begin
            crate_x = 12'd1104;
            crate_y = 12'd208;
        end
        5'd4: begin
            crate_x = 12'd272;
            crate_y = 12'd272;
        end
        5'd5: begin
            crate_x = 12'd1744;
            crate_y = 12'd272;
        end
        5'd6: begin
            crate_x = 12'd272;
            crate_y = 12'd464;
        end
        5'd7: begin
            crate_x = 12'd912;
            crate_y = 12'd464;
        end
        5'd8: begin
            crate_x = 12'd1104;
            crate_y = 12'd464;
        end
        5'd9: begin
            crate_x = 12'd1744;
            crate_y = 12'd464;
        end
        5'd10: begin
            crate_x = 12'd272;
            crate_y = 12'd656;
        end
        5'd11: begin
            crate_x = 12'd1744;
            crate_y = 12'd656;
        end
        5'd12: begin
            crate_x = 12'd912;
            crate_y = 12'd848;
        end
        5'd13: begin
            crate_x = 12'd1104;
            crate_y = 12'd848;
        end
        5'd14: begin
            crate_x = 12'd784;
            crate_y = 12'd912;
        end
        5'd15: begin
            crate_x = 12'd1232;
            crate_y = 12'd912;
        end
        5'd16: begin
            crate_x = 12'd784;
            crate_y = 12'd1104;
        end
        5'd17: begin
            crate_x = 12'd1232;
            crate_y = 12'd1104;
        end
        5'd18: begin
            crate_x = 12'd912;
            crate_y = 12'd1168;
        end
        5'd19: begin
            crate_x = 12'd1104;
            crate_y = 12'd1168;
        end
        5'd20: begin
            crate_x = 12'd272;
            crate_y = 12'd1360;
        end
        5'd21: begin
            crate_x = 12'd1744;
            crate_y = 12'd1360;
        end
        5'd22: begin
            crate_x = 12'd272;
            crate_y = 12'd1552;
        end
        5'd23: begin
            crate_x = 12'd912;
            crate_y = 12'd1552;
        end
        5'd24: begin
            crate_x = 12'd1104;
            crate_y = 12'd1552;
        end
        5'd25: begin
            crate_x = 12'd1744;
            crate_y = 12'd1552;
        end
        5'd26: begin
            crate_x = 12'd272;
            crate_y = 12'd1744;
        end
        5'd27: begin
            crate_x = 12'd1744;
            crate_y = 12'd1744;
        end
        5'd28: begin
            crate_x = 12'd912;
            crate_y = 12'd1808;
        end
        5'd29: begin
            crate_x = 12'd1104;
            crate_y = 12'd1808;
        end
        5'd30: begin
            crate_x = 12'd208;
            crate_y = 12'd1936;
        end
        5'd31: begin
            crate_x = 12'd1808;
            crate_y = 12'd1936;
        end
        default: begin
            crate_x = 12'd0;
            crate_y = 12'd0;
        end
    endcase
end

endmodule