#!/bin/sh

curl -v -X POST http://lambda.example.com/test/ -d '{"name": "Bill",  "greeting": "hello"}'
