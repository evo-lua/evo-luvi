// #include "llhttp.h"
#include "llhttp.c"
#include <stdio.h>
#include <string.h>

const int NUM_REQUESTS_TO_PARSE = 50000000;

void ParseRequests(llhttp_t parser) {
	const char* request = "GET / HTTP/1.1\r\n\r\n";
	// const char* request = "GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n";
	int request_len = strlen(request);

	// printf("Parsing %d requests...\n", NUM_REQUESTS_TO_PARSE);
	for(int i=0; i < NUM_REQUESTS_TO_PARSE; i++) {
		llhttp_execute(&parser, request, request_len);
		llhttp_finish(&parser);
		llhttp_reset(&parser);
	}
	// printf("Done!\n");
	// Benchmark with 'time cbench.exe' since it's a PITA to measure time in C...
}

int main() {
	// printf("Initializing llhttp structures...\n");
	static llhttp_t parser;
	static llhttp_settings_t settings;
	llhttp_init(&parser, HTTP_BOTH, &settings);

	ParseRequests(parser);
}