#!/bin/sh

curl -v -X POST http://lambda.example.com:81/ -d '{"name": "Bill",  "greeting": "hello"}'