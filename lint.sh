#!/bin/sh

eslint \
	. \
	--ext ".mjs" \
	--config ./eslint.config.js
