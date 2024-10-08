#!/bin/sh

curl -v -X POST http://lambda.example.com/ -d '{"name": "Bill",  "greeting": "hello"}'

# curl -v -X POST -H "Host: lambda.example.com" http://127.0.0.1:8000/ -d '{"name": "Bill",  "greeting": "hello"}'
