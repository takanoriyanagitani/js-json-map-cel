import { fileURLToPath } from "url";
import { Environment } from "@marcbachmann/cel-js";

/** @import {TypeCheckResult} from "@marcbachmann/cel-js" */

/**
 * @param {string} objName
 * @param {string} expr
 * @returns {function(any): any}
 */
function createObjMapper(objName = "item", expr = "") {
  const permissive = process.env.CEL_PERMISSIVE_TYPES === "1" ||
    process.env.CEL_PERMISSIVE_TYPES === "true";
  const envOptions = {
    homogeneousAggregateLiterals: !permissive,
  };

  /** @type {Environment} */
  const env = new Environment(envOptions)
    .registerVariable(objName, "map");

  /** @type {TypeCheckResult} */
  const checkResult = env.check(expr);

  if (!checkResult.valid) {
    return function (_) {
      return checkResult.error;
    };
  }

  const parsed = env.parse(expr);

  /** @type {function(any): any} */
  return function (ctx) {
    return parsed(ctx);
  };
}

/**
 * Main function to run CEL mapping from environment variable and stdin.
 */
async function runCelMapping() {
  const exprString = process.env.EXPR_STRING;

  if (!exprString) {
    console.error("Error: EXPR_STRING environment variable not set.");
    process.exit(1);
  }

  const mapper = createObjMapper("input", exprString);

  let inputData = "";
  process.stdin.setEncoding("utf8");

  for await (const chunk of process.stdin) {
    inputData += chunk;
  }

  try {
    const parsedInput = JSON.parse(inputData);
    // The mapper expects an object with the variable name as key
    const result = mapper({ input: parsedInput });
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("Error processing input:", error);
    process.exit(1);
  }
}

// Check if this module is run directly
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  runCelMapping();
}
