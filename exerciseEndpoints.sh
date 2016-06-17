#!/bin/sh

clear

echo + quote-service endpoints
echo "\n"
echo ++ HAL Browser
curl -X GET http://localhost:8088
echo "\n"
echo ++ All quotes
curl -X GET http://localhost:8088/quotes
echo "\n"
echo ++ Random quote
curl -X GET http://localhost:8088/random

echo "\n"
echo "\n"
echo + edge-service endpoints
echo "\n"
echo ++ Zuul microproxy passthroughs to quote-service
echo +++ All quotes
curl -X GET http://localhost:8086/qs/quotes
echo "\n"
echo +++ Random quote
curl -X GET http://localhost:8086/qs/random
echo "\n"
echo ++ Direct access to defined endpoint in edge-service
curl -X GET http://localhost:8086/quotorama
echo "\n"
echo ++ Zuul route to defined endpoint, which then uses RestTemplate to access quote-service.
echo ++ NOTE: This is a contrived example I use to explain/demo how Zuul intelligent routing
echo ++       works. Although unorthodox, it is 100% compliant with the Spring Cloud Zuul
echo ++       documentation - up to and including June 15, 2016, at least.
curl -X GET http://localhost:8086/quote
echo "\n"
# echo ++ POST to /newquote for testing RabbitMQ
# echo ++ NOTE: Must have a RabbitMQ instance running and code built with relevant code enabled.
# curl -X POST -H "Content-Type: application/json" -d '{"text":"Another test quote.","source":"Me"}' http://localhost:8086/newquote
echo "\n"
