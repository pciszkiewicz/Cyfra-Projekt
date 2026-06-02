/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description: 
 * Table of positions (LUT) mapping crate ID (0-31) to global map coordinates.
 * Coordinates are kept for 2048x2048 map resolution (64x64 tiles).
 */

 module crate_lut (
    input  logic [4:0]  crate_id,
    output logic [11:0] crate_x,
    output logic [11:0] crate_y
);
always_comb begin
    case (crate_id)
        // Kwadrant 1 (Lewa Góra)
        5'd0:  begin crate_x = 12'd192;  crate_y = 12'd192;  end
        5'd1:  begin crate_x = 12'd768;  crate_y = 12'd192;  end
        5'd2:  begin crate_x = 12'd192;  crate_y = 12'd768;  end
        5'd3:  begin crate_x = 12'd768;  crate_y = 12'd768;  end
        5'd4:  begin crate_x = 12'd480;  crate_y = 12'd256;  end
        5'd5:  begin crate_x = 12'd480;  crate_y = 12'd704;  end
        5'd6:  begin crate_x = 12'd256;  crate_y = 12'd480;  end
        5'd7:  begin crate_x = 12'd704;  crate_y = 12'd480;  end
        // Kwadrant 2 (Prawa Góra)
        5'd8:  begin crate_x = 12'd1824; crate_y = 12'd192;  end
        5'd9:  begin crate_x = 12'd1248; crate_y = 12'd192;  end
        5'd10: begin crate_x = 12'd1824; crate_y = 12'd768;  end
        5'd11: begin crate_x = 12'd1248; crate_y = 12'd768;  end
        5'd12: begin crate_x = 12'd1536; crate_y = 12'd256;  end
        5'd13: begin crate_x = 12'd1536; crate_y = 12'd704;  end
        5'd14: begin crate_x = 12'd1760; crate_y = 12'd480;  end
        5'd15: begin crate_x = 12'd1312; crate_y = 12'd480;  end
        // Kwadrant 3 (Lewy Dół)
        5'd16: begin crate_x = 12'd192;  crate_y = 12'd1824; end
        5'd17: begin crate_x = 12'd768;  crate_y = 12'd1824; end
        5'd18: begin crate_x = 12'd192;  crate_y = 12'd1248; end
        5'd19: begin crate_x = 12'd768;  crate_y = 12'd1248; end
        5'd20: begin crate_x = 12'd480;  crate_y = 12'd1760; end
        5'd21: begin crate_x = 12'd480;  crate_y = 12'd1312; end
        5'd22: begin crate_x = 12'd256;  crate_y = 12'd1536; end
        5'd23: begin crate_x = 12'd704;  crate_y = 12'd1536; end
        // Kwadrant 4 (Prawy Dół)
        5'd24: begin crate_x = 12'd1824; crate_y = 12'd1824; end
        5'd25: begin crate_x = 12'd1248; crate_y = 12'd1824; end
        5'd26: begin crate_x = 12'd1824; crate_y = 12'd1248; end
        5'd27: begin crate_x = 12'd1248; crate_y = 12'd1248; end
        5'd28: begin crate_x = 12'd1536; crate_y = 12'd1760; end
        5'd29: begin crate_x = 12'd1536; crate_y = 12'd1312; end
        5'd30: begin crate_x = 12'd1760; crate_y = 12'd1536; end
        5'd31: begin crate_x = 12'd1312; crate_y = 12'd1536; end
        default: begin
            crate_x = 12'd0;
            crate_y = 12'd0;
        end
    endcase
end
endmodule