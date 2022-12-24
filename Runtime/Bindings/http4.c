#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_HEADERS 100

// Define a structure to represent a HTTP message
typedef struct {
  char method[16];
  char uri[256];
  char http_version[16];
  struct {
    char name[256];
    char value[4096];
  } headers[MAX_HEADERS];
  size_t num_headers;
  char body[4096];
} http_message_t;

// Define callback functions to handle the various events that the parser can trigger
void on_method(http_message_t *http_message, const char *method, size_t length) {
  if (length > sizeof(http_message->method) - 1) {
    length = sizeof(http_message->method) - 1;
  }
  strncpy(http_message->method, method, length);
  http_message->method[length] = '\0';
}

void on_uri(http_message_t *http_message, const char *uri, size_t length) {
  if (length > sizeof(http_message->uri) - 1) {
    length = sizeof(http_message->uri) - 1;
  }
  strncpy(http_message->uri, uri, length);
  http_message->uri[length] = '\0';
}

void on_http_version(http_message_t *http_message, const char *http_version, size_t length) {
  if (length > sizeof(http_message->http_version) - 1) {
    length = sizeof(http_message->http_version) - 1;
  }
  strncpy(http_message->http_version, http_version, length);
  http_message->http_version[length] = '\0';
}

void on_header(http_message_t *http_message, const char *name, size_t name_length, const char *value, size_t value_length) {
  if (name_length > sizeof(http_message->headers[http_message->num_headers].name) - 1) {
    name_length = sizeof(http_message->headers[http_message->num_headers].name) - 1;
  }
  if (value_length > sizeof(http_message->headers[http_message->num_headers].value) - 1) {
    value
