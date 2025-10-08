#!/usr/bin/env nix-shell
/*
#!nix-shell -i bun -p bun
*/

import fs from "node:fs";
import nyquist_5 from "./enryco_nyquist_rev3_5.json";
import nyquist_4 from "./enryco_nyquist_rev3_4.json";

// Convert from 5 to 4 (remove top row)
function convertFrom5To4() {
	const path = "./enryco_nyquist_rev3_4.json";
	const result = { ...nyquist_5 };

	result.layout = "LAYOUT_ortho_4x12";

	result.layers.forEach((layer, index) => {
		result.layers[index] = layer.splice(12);
	});

	fs.writeFileSync(path, JSON.stringify(result, null, 2));
	console.log(`✅ Converted 5-row to 4-row layout: ${path}`);
}

// Convert from 4 to 5 (add top row)
function convertFrom4To5() {
	const path = "./enryco_nyquist_rev3_5.json";
	const result = { ...nyquist_4 };

	result.layout = "LAYOUT_ortho_5x12";

	// Default top row keys (numbers and escape)
	// const defaultTopRow = [
	// 	"KC_ESC", "KC_1", "KC_2", "KC_3", "KC_4", "KC_5",
	// 	"KC_6", "KC_7", "KC_8", "KC_9", "KC_0", "KC_ESC"
	// ];

	const defaultTopRow = [
		"KC_NO", "KC_NO", "KC_NO", "KC_NO", "KC_NO", "KC_NO",
		"KC_NO", "KC_NO", "KC_NO", "KC_NO", "KC_NO", "KC_NO"
	];

	result.layers.forEach((layer, index) => {
		// Add the default top row to the beginning of each layer
		result.layers[index] = [...defaultTopRow, ...layer];
	});

	fs.writeFileSync(path, JSON.stringify(result, null, 2));
	console.log(`✅ Converted 4-row to 5-row layout: ${path}`);
}

// CLI handling
function showUsage() {
	console.log(`
Usage: bun convert.js <command>

Commands:
	from5    Convert from 5-row to 4-row layout
	from4    Convert from 4-row to 5-row layout
	help    Show this help message

Examples:
	bun convert.js from5
	bun convert.js from4
`);
}

// Main execution
const command = process.argv[2];

switch (command) {
	case "from5":
		convertFrom5To4();
		break;
	case "from4":
		convertFrom4To5();
		break;
	case "help":
	case "--help":
	case "-h":
		showUsage();
		break;
	default:
		console.error("❌ Invalid or missing command");
		showUsage();
		process.exit(1);
}
