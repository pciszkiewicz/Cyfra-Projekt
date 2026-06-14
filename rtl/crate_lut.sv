/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description: 
 * Zbalansowany LUT do mapy "Classic Arena".
 * Map resolution: 64x64 tiles. Each tile = 32px.
 * Bardzo czytelna geometria - koniec z labiryntem!
 */

 module crate_lut (
    input  logic [4:0]  crate_id,
    output logic [15:0] crate_x,
    output logic [15:0] crate_y
);

always_comb begin
    case (crate_id)
        // ----------------------------------------------------
        // GRUPA 1: Narożne "L-ki" (Bezpieczna osłona na start)
        5'd0:  begin crate_x = 16'd384;  crate_y = 16'd384;  end // Lewa Góra L1
        5'd1:  begin crate_x = 16'd512;  crate_y = 16'd384;  end // Lewa Góra L2
        5'd2:  begin crate_x = 16'd1504; crate_y = 16'd384;  end // Prawa Góra L1
        5'd3:  begin crate_x = 16'd1632; crate_y = 16'd384;  end // Prawa Góra L2
        5'd4:  begin crate_x = 16'd384;  crate_y = 16'd1632; end // Lewy Dół L1
        5'd5:  begin crate_x = 16'd512;  crate_y = 16'd1632; end // Lewy Dół L2
        5'd6:  begin crate_x = 16'd1504; crate_y = 16'd1632; end // Prawy Dół L1
        5'd7:  begin crate_x = 16'd1632; crate_y = 16'd1632; end // Prawy Dół L2

        // ----------------------------------------------------
        // GRUPA 2: Flanki (Obwodowe ścieżki wokół mapy)
        5'd8:  begin crate_x = 16'd1024; crate_y = 16'd128;  end // Północ
        5'd9:  begin crate_x = 16'd1024; crate_y = 16'd1888; end // Południe
        5'd10: begin crate_x = 16'd128;  crate_y = 16'd1024; end // Zachód
        5'd11: begin crate_x = 16'd1888; crate_y = 16'd1024; end // Wschód

// ----------------------------------------------------
        // GRUPA 3: Narożniki potężnego "+ " na środku (Epicentrum walki)
        // Wciśnięte w wewnętrzne kąty krzyża - idealna zasłona!
        5'd12: begin crate_x = 16'd832;  crate_y = 16'd896;  end // Wew. Róg LG
        5'd13: begin crate_x = 16'd1056; crate_y = 16'd896;  end // Wew. Róg PG
        5'd14: begin crate_x = 16'd832;  crate_y = 16'd1120; end // Wew. Róg LD
        5'd15: begin crate_x = 16'd1056; crate_y = 16'd1120; end // Wew. Róg PD
        
        // ----------------------------------------------------
        // GRUPA 4: Otwarte pole (Ziemia niczyja miedzy rogiem a srodkiem)
        5'd16: begin crate_x = 16'd640;  crate_y = 16'd640;  end
        5'd17: begin crate_x = 16'd1376; crate_y = 16'd640;  end
        5'd18: begin crate_x = 16'd640;  crate_y = 16'd1376; end
        5'd19: begin crate_x = 16'd1376; crate_y = 16'd1376; end

        // ----------------------------------------------------
        // GRUPA 5: Wąskie przejścia w osi pionowej (Gateway)
        5'd20: begin crate_x = 16'd768;  crate_y = 16'd512;  end
        5'd21: begin crate_x = 16'd1248; crate_y = 16'd512;  end
        5'd22: begin crate_x = 16'd768;  crate_y = 16'd1504; end
        5'd23: begin crate_x = 16'd1248; crate_y = 16'd1504; end

        // ----------------------------------------------------
        // GRUPA 6: Wąskie przejścia w osi poziomej (Gateway)
        5'd24: begin crate_x = 16'd512;  crate_y = 16'd768;  end
        5'd25: begin crate_x = 16'd1504; crate_y = 16'd768;  end
        5'd26: begin crate_x = 16'd512;  crate_y = 16'd1248; end
        5'd27: begin crate_x = 16'd1504; crate_y = 16'd1248; end

        // ----------------------------------------------------
        // GRUPA 7: "Głębokie rogi" (Dla snajperów i uciekinierów)
        5'd28: begin crate_x = 16'd64;   crate_y = 16'd64;   end // Ext. LG
        5'd29: begin crate_x = 16'd1952; crate_y = 16'd64;   end // Ext. PG
        5'd30: begin crate_x = 16'd64;   crate_y = 16'd1952; end // Ext. LD
        5'd31: begin crate_x = 16'd1952; crate_y = 16'd1952; end // Ext. PD
        
        default: begin
            crate_x = 16'd0;
            crate_y = 16'd0;
        end
    endcase
end
endmodule