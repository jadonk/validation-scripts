#!/usr/bin/env node
c=require('connect');
c().use(c.static('.')).listen(80);
