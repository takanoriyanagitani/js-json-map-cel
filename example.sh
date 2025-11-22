#!/bin/sh

ex1() {
	echo "--- Running Example 1 (all conditions should pass) ---"
	jq -c -n '{
    time: "2025-11-20T07:13:46.012Z",
    severity: "INFO",
    status: 200,
    body: "apt update done",
  }' | EXPR_STRING='{
    "time_ok": 0 < input.time.size(),
    "severity_ok": input.severity in ["INFO", "WARN", "FATAL"],
    "status_ok": 100 <= input.status && input.status < 600,
    "body_ok": 0 < input.body.size(),
  }' node ./index.mjs
}

ex2() {
	echo "\n--- Running Example 2 (severity should fail) ---"
	jq -c -n '{
    time: "2025-11-20T07:13:46.012Z",
    severity: "DEBUG",
    status: 200,
    body: "apt update done",
  }' | EXPR_STRING='{
    "time_check": 0 < input.time.size() ? "ok" : "invalid time string: " + input.time,
    "severity_check": input.severity in ["INFO", "WARN", "FATAL"]
        ? "ok"
        : "invalid severity string: " + input.severity,
    "status_ok": string(100 <= input.status && input.status < 600),
    "body_ok": string(0 < input.body.size()),
  }' node ./index.mjs
}

ex1
ex2

ex3() {
	echo "\n--- Running Example 3 (permissive mode with mixed types) ---"
	jq -c -n '{
    time: "2025-11-20T07:13:46.012Z",
    severity: "DEBUG",
    status: 200,
    body: "apt update done",
  }' | CEL_PERMISSIVE_TYPES=1 EXPR_STRING='{
    "time_check": 0 < input.time.size() ? "ok" : "invalid time string: " + input.time,
    "severity_check": input.severity in ["INFO", "WARN", "FATAL"]
        ? "ok"
        : "invalid severity string: " + input.severity,
    "status_ok": 100 <= input.status && input.status < 600,
    "body_ok": 0 < input.body.size(),
  }' node ./index.mjs
}

ex3

ex4() {
	echo "\n--- Running Example 4 (strict mode with explicit dyn casts) ---"
	jq -c -n '{
    "int_val": 1,
    "string_val": "hello"
  }' | EXPR_STRING='{ "int_key": dyn(input.int_val), "string_key": dyn(input.string_val) }' node ./index.mjs
}

ex4
