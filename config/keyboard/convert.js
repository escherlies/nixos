import fs from "node:fs";
import nyquist_5 from "./enryco_nyquist_rev3_5.json";

(() => {
	const path = "./enryco_nyquist_rev3_4.json";
	const result = { ...nyquist_5 };

	result.layout = "LAYOUT_ortho_4x12";

	result.layers.forEach((layer, index) => {
		result.layers[index] = layer.splice(12);
	});

	fs.writeFileSync(path, JSON.stringify(result, null, 2));
})();
